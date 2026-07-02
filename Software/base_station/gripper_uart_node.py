#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from std_msgs.msg import String
import json
import serial
import RPi.GPIO as GPIO


# MAX3485 half-duplex logic constants
RS485_TX = GPIO.HIGH
RS485_RX = GPIO.LOW

class GripperBinaryUartNode(Node):
    def __init__(self):
        super().__init__('gripper_binary_uart_bridge')
        
        # 1. Initialize MAX3485 Direction Control Pin
        self.DIR_PIN = 18
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.DIR_PIN, GPIO.OUT)
        
        # Immediately default to RX mode to prevent locking or jamming the RS-485 bus
        GPIO.output(self.DIR_PIN, RS485_RX)

        # 2. Initialize Hardware Serial Port via GPIO Pins 14 (TX) & 15 (RX)
        try:
            self.ser = serial.Serial(
                port='/dev/ttyAMA0', # Built-in hardware UART on Raspberry Pi
                baudrate=115200,
                timeout=0.2          # 200ms timeout waiting for 'k' acknowledgment
            )
            self.get_logger().info('🔌 Gripper Hardware RS-485 Interface Initialized (TX=14, RX=15, DIR=18).')
        except Exception as e:
            self.get_logger().error(f'❌ Failed to open Hardware UART port: {str(e)}')
            self.ser = None

        self.subscription = self.create_subscription(
            String,
            '/gripper_controller/spatial_trap',
            self.gripper_callback,
            10
        )

    def encode_coordinate(self, value_mm):
        """
        Multiplies millimeter float value by 16, converts to integer,
        and isolates into high (4-bit) and low (8-bit) byte segments.
        Handles negative values natively via 12-bit two's complement masking.
        """
        # 1. Scale value by 16
        scaled_value = int(round(value_mm * 16))
        
        # 2. Mask to 12-bit to safely manage negative numbers (& 0xFFF)
        val_12bit = scaled_value & 0xFFF
        
        # 3. Extract bits [11:8] into the lowest 4 bits of the high byte
        high_byte = (val_12bit >> 8) & 0x0F
        
        # 4. Extract bits [7:0] into the low byte
        low_byte = val_12bit & 0xFF
        
        return high_byte, low_byte

    def gripper_callback(self, msg):
        if not self.ser or not self.ser.is_open:
            self.get_logger().warn('UART port offline. Command dropped.')
            return

        try:
            # Parse the JSON string coming from the React client
            coords = json.loads(msg.data)
            x_mm = coords.get('x', 0.0)
            y_mm = coords.get('y', 0.0)
            z_mm = coords.get('z', 0.0)
            enb =  coords.get('enable', 0)

            # Convert values into binary segments using our helper function
            x_high, x_low = self.encode_coordinate(x_mm)
            y_high, y_low = self.encode_coordinate(y_mm)
            z_high, z_low = self.encode_coordinate(z_mm)

            # Compile the structured 7-byte binary frame package
            packet = bytes([
                0xAA,   # Frame Sync Header
                x_high, 
                x_low,
                y_high, 
                y_low,
                z_high, 
                z_low,
                enb
            ])

            # Debug output to verify bit-packing operations inside terminal
            self.get_logger().info(f"Outbound RS-485 Frame: {packet.hex().upper()}")

            # Purge any stale bytes left over in buffers before transmission
            self.ser.reset_input_buffer()
            
            # --- CRITICAL RS-485 HALF-DUPLEX TRANSITION SEQUENCE ---
            # Step A: Pull DE/RE High to switch MAX3485 into Transmit Mode
            GPIO.output(self.DIR_PIN, RS485_TX)
            
            # Step B: Write raw packet to serial subsystem buffer
            self.ser.write(packet)
            
            # Step C: Force Python to block until physical hardware TX shift register is completely clear
            self.ser.flush()
            
            # Step D: Instantly flip back to Receive Mode to prevent clipping response frames
            GPIO.output(self.DIR_PIN, RS485_RX)
            # -------------------------------------------------------

            # Blocking read window check for the acknowledgement byte ('k')
            ack = self.ser.read(1)

            self.get_logger().info(ack)

            if ack == b'K':
                self.get_logger().info("Transaction Completed: Handshake 'k' received.")
            elif len(ack) == 0:
                self.get_logger().error("Transaction Timeout: No acknowledgment received from gripper firmware.")
            else:
                self.get_logger().warn(f"Transaction Corrupted: Received unexpected response token: {ack}")

        except json.JSONDecodeError:
            self.get_logger().error('Dropping corrupt message: Failed JSON payload parsing.')
        except Exception as e:
            self.get_logger().error(f'Pipeline Execution Failure: {str(e)}')
            # Safety fallback: Ensure a driver crash leaves the transceiver listening
            if hasattr(self, 'DIR_PIN'):
                GPIO.output(self.DIR_PIN, RS485_RX)

    def destroy_node(self):
        # Gracefully handle ports and clean up GPIO states on closure
        if hasattr(self, 'ser') and self.ser and self.ser.is_open:
            self.ser.close()
        try:
            GPIO.output(self.DIR_PIN, RS485_RX)
            GPIO.cleanup()
            self.get_logger().info('GPIO cleaned up and bus released safely.')
        except Exception:
            pass
        super().destroy_node()

def main(args=None):
    rclpy.init(args=args)
    node = GripperBinaryUartNode()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()