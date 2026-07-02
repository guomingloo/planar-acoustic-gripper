import React, { useState, useEffect, useRef } from 'react'; 
import ROSLIB from 'roslib'; 

// Centralized Theme System Object
const THEME = { 
    dark: { 
        bg: "bg-[#121212]", 
        text: "text-[#E0E0E0]", 
        border: "border-[#2D2D2D]", 
        panelBg: "bg-[#121212]", 
        macroHover: "hover:bg-[#1A1A1A]" 
    },
    light: { 
        bg: "bg-[#FFFEFA]", 
        text: "text-[#212529]", 
        border: "border-[#EBEAE8]", 
        panelBg: "bg-[#FFFEFA]", 
        macroHover: "hover:bg-[#FFEFC9]" 
    }
}; 

export default function RoboticDashboard() { 
    const [darkMode, setDarkMode] = useState(true); 
    const [isAuthenticated, setIsAuthenticated] = useState(false); 
    const [username, setUsername] = useState(''); 
    const [password, setPassword] = useState(''); 
    const [viewMode, setViewMode] = useState('model'); 
    const [mobileTab, setMobileTab] = useState('visualizer'); 

    // Core telemetry/active hardware state - Upgraded to 7-Axis Kinematics
    const [robotState, setRobotState] = useState({ j1: 45, j2: 30, j3: 90, j4: 0, j5: 15, j6: 0, j7: 0 }); 
    const [trapState, setTrapState] = useState({ x: 20, y: 21.4, z: 25, intensity: 80 }); 
    const [cameraFocus, setCameraFocus] = useState('arm'); 

    // Staging States for Slider Manipulation - Upgraded to 7-Axis Kinematics
    const [stagedRobot, setStagedRobot] = useState({ j1: 45, j2: 30, j3: 90, j4: 0, j5: 15, j6: 0, j7: 0 }); 
    const [stagedTrap, setStagedTrap] = useState({ x: 20, y: 21.4, z: 25, intensity: 80 }); 
    const [liveUpdate, setLiveUpdate] = useState(true); 

    // Converted to exactly 4 macro slots with 7-axis parameters included
    const [macros, setMacros] = useState([ 
        { id: 1, name: 'Home Pos', robot: { j1: 0, j2: 0, j3: 0, j4: 0, j5: 0, j6: 0, j7: 0 }, trap: { x: 0, y: 0, z: 0 } }, 
        { id: 2, name: 'Pick Object', robot: { j1: 45, j2: 60, j3: 45, j4: 0, j5: 10, j6: 0, j7: 45 }, trap: { x: 5, y: -5, z: 12 } }, 
        { id: 3, name: 'Acoustic Lev', robot: { j1: 90, j2: 30, j3: 90, j4: 0, j5: 0, j6: 0, j7: -90 }, trap: { x: 2, y: -2, z: 15 } }, 
        { id: 4, name: 'Macro Slot 4', robot: { j1: 10, j2: 10, j3: 10, h4: 10, j5: 10, j6: 10, j7: 10 }, trap: { x: 1, y: 1, z: 2 } }, 
    ]); 
    const [isEditingMacros, setIsEditingMacros] = useState(false); 
    const [snappedId, setSnappedId] = useState(null); 
    const activeTheme = darkMode ? THEME.dark : THEME.light; 

    const ros = useRef(null); 
    const jointTopic = useRef(null); 
    const gripperTopic = useRef(null); 
    const isSecure = window.location.protocol === 'https:'; 
    const wsProtocol = isSecure ? 'wss:' : 'ws:'; 
    const targetProtocol = window.location.hostname.includes('xyz') ? 'wss:' : wsProtocol;
    useEffect(() => {
        ros.current = new ROSLIB.Ros({
            url: `${targetProtocol}//ros.${window.location.hostname}`
        });

        ros.current.on('connection', () => console.log('📡 Connected to ROS 2 Core')); 
        ros.current.on('error', (error) => console.error('🚨 ROS Bridge Error:', error)); 
        ros.current.on('close', () => console.log('🔌 ROS Bridge Connection Closed')); 

        jointTopic.current = new ROSLIB.Topic({ 
            ros: ros.current, 
            name: '/arm_controller/joint_commands', 
            messageType: 'std_msgs/msg/Float64MultiArray' 
        }); 

        gripperTopic.current = new ROSLIB.Topic({ 
            ros: ros.current, 
            name: '/gripper_controller/spatial_trap', 
            messageType: 'std_msgs/msg/String' 
        }); 

        return () => ros.current?.close(); 
    }, [wsProtocol]); 

    const handleLogin = (e) => { 
        e.preventDefault(); 
        if ((username === '123' && password === '123') || (username === 'admin' && password === 'pi-control')) { 
            setIsAuthenticated(true); 
        } else { 
            alert("Invalid testing credentials! Use 123 / 123 or admin / pi-control"); 
        } 
    }; 

    // Unified live/staged data state manager with streaming hooks for ROS 2
    const triggerParamChange = (type, field, value) => { 
        if (!isAuthenticated) return; 
        let updatedRobot = { ...stagedRobot }; 
        let updatedTrap = { ...stagedTrap }; 

        if (type === 'robot') { 
            updatedRobot[field] = value; 
            setStagedRobot(updatedRobot); 
            if (liveUpdate) { 
                setRobotState(updatedRobot); 
                setCameraFocus('arm'); 
                if (jointTopic.current) { 
                    jointTopic.current.publish(new ROSLIB.Message({ 
                        data: [ 
                            updatedRobot.j1, updatedRobot.j2, updatedRobot.j3, 
                            updatedRobot.j4, updatedRobot.j5, updatedRobot.j6, updatedRobot.j7 
                        ] 
                    })); 
                } 
            } 
        } else { 
            updatedTrap[field] = value; 
            setStagedTrap(updatedTrap); 
            if (liveUpdate) { 
                setTrapState(updatedTrap); 
                setCameraFocus('gripper'); 
                if (gripperTopic.current) { 
                    gripperTopic.current.publish(new ROSLIB.Message({ 
                        data: JSON.stringify(updatedTrap) 
                    })); 
                } 
            } 
        } 
    }; 

    // Explicit manual push handler (used when LIVE STREAMING is off)
    const handleSendData = () => { 
        setRobotState(stagedRobot); 
        setTrapState(stagedTrap); 

        if (jointTopic.current && gripperTopic.current) { 
            jointTopic.current.publish(new ROSLIB.Message({ 
                data: [stagedRobot.j1, stagedRobot.j2, stagedRobot.j3, stagedRobot.j4, stagedRobot.j5, stagedRobot.j6, stagedRobot.j7]
            })); 
            gripperTopic.current.publish(new ROSLIB.Message({ 
                data: JSON.stringify(stagedTrap) 
            })); 
        } // 
    }; // 

    return ( // 
        <div className={`h-screen w-screen overflow-hidden text-xs select-none font-mono flex flex-col ${activeTheme.bg} ${activeTheme.text}`}> {/*  */}
            
            {/* ADAPTIVE MULTI-ROW HEADER PANEL */}
            <header className={`min-h-12 border-b flex flex-col md:flex-row items-center justify-between px-4 py-2 md:py-0 gap-2 shrink-0 relative ${activeTheme.border}`}>
                <div className="flex items-center justify-between w-full md:w-auto gap-3">
                    <div className="flex items-center gap-3">
                        <span className="font-bold tracking-widest text-sm">Acoustic Gripper Dashboard</span>
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${isAuthenticated ? 'bg-emerald-500/10 text-emerald-400' : 'bg-amber-500/10 text-amber-500'}`}>
                            {isAuthenticated ? '● CONTROL LIVE' : '○ TELEMETRY LOCK'}
                        </span> 
                    </div>
                    
                    {/* Mobile Quick Light/Dark Switcher */}
                    <button 
                        onClick={() => setDarkMode(!darkMode)} 
                        className="md:hidden px-2 py-1 text-[10px] font-bold border rounded border-neutral-700/40"
                    >
                        {darkMode ? 'Light' : 'Dark'}
                    </button>
                </div>
                
                {/* Responsive 4-Tab Control Array for Finger Comfort */}
                <div className="flex lg:hidden border rounded overflow-hidden text-[10px] border-neutral-500/30 w-full sm:w-auto justify-center">
                    <button onClick={() => setMobileTab('states')} className={`flex-1 sm:flex-initial px-3 py-1.5 font-bold ${mobileTab === 'states' ? 'bg-neutral-500/20 text-amber-500' : ''}`}>Data</button>
                    <button onClick={() => setMobileTab('visualizer')} className={`flex-1 sm:flex-initial px-3 py-1.5 font-bold ${mobileTab === 'visualizer' ? 'bg-neutral-500/20 text-amber-500' : ''}`}>View</button>
                    <button onClick={() => setMobileTab('acoustic')} className={`flex-1 sm:flex-initial px-3 py-1.5 font-bold ${mobileTab === 'acoustic' ? 'bg-neutral-500/20 text-amber-500' : ''}`}>Acoustic</button>
                    <button onClick={() => setMobileTab('controls')} className={`flex-1 sm:flex-initial px-3 py-1.5 font-bold ${mobileTab === 'controls' ? 'bg-neutral-500/20 text-amber-500' : ''}`}>Input</button>
                </div>

                <div className="flex items-center gap-3 h-8 w-full md:w-auto justify-end">
                    {!isAuthenticated && ( // 
                        <form onSubmit={handleLogin} className="flex items-center gap-2 w-full md:w-auto justify-end">
                            <input
                                type="text" placeholder="User" value={username}
                                className={`bg-transparent border h-8 px-2 outline-none max-w-[80px] rounded text-sm ${activeTheme?.border || 'border-neutral-600'}`} 
                                onChange={e => setUsername(e.target.value)} 
                            /> 
                            <input 
                                type="password" placeholder="Pass" value={password} 
                                className={`bg-transparent border h-8 px-2 outline-none max-w-[80px] rounded text-sm ${activeTheme?.border || 'border-neutral-600'}`} 
                                onChange={e => setPassword(e.target.value)} 
                            /> 
                            <button type="submit" className={`border h-8 px-3 text-sm rounded hover:bg-neutral-500/20 ${activeTheme?.border || 'border-neutral-600'}`}>Login</button>
                        </form>
                    )}
                 
                    <div className={`hidden md:flex items-center justify-center border-2 h-8 w-20 rounded ${activeTheme.border}`}>
                        <button onClick={() => setDarkMode(!darkMode)} className="w-full h-full font-bold text-xs text-center focus:outline-none select-none">
                            {darkMode ? 'Light' : 'Dark'}
                        </button> 
                    </div> 
                </div> 
            </header>

            <div className="w-full flex-1 flex flex-col lg:flex-row relative min-h-0">
        
                <div className={`w-full lg:w-1/4 h-full flex flex-col border-r relative ${activeTheme.border} ${mobileTab !== 'states' ? 'hidden lg:flex' : 'flex'}`}>
                    <div className="h-[55%] p-4 border-b border-inherit overflow-y-auto style-scrollbar">
                        <h2 className="font-bold tracking-wider mb-4 text-neutral-400">// 7-AXIS ARM HW FEEDBACK</h2>
                        <div className="space-y-2.5"> 
                           {Object.entries(robotState).map(([joint, val]) => ( 
                                <div key={joint} className="flex justify-between items-center border-b border-dashed pb-0.5 border-neutral-700/20">
                                    <span className="uppercase font-semibold">{joint} target posture</span>
                                    <span className="font-bold text-emerald-400">{val}°</span>
                                </div> 
                            ))}
                        </div>
                    </div>

                    {/* Instant Macros Grid Container */}
                    <div className="h-[45%] p-4 flex flex-col justify-between">
                        <div className="flex justify-between items-center mb-2">
                            <h2 className="font-bold tracking-wider text-neutral-400">// INSTANT MACROS (4 SLOTS)</h2> {/* [cite: 51] */}
                            <button
                                disabled={!isAuthenticated}
                                onClick={() => !isEditingMacros ? setIsEditingMacros(true) : setIsEditingMacros(false)}
                                className={`text-[10px] font-bold tracking-tight px-1.5 py-0.5 rounded border ${
                                    !isAuthenticated
                                        ? 'opacity-30 border-transparent'
                                        : isEditingMacros
                                        ? 'border-emerald-500/40 bg-emerald-500/10 text-emerald-400'
                                        : 'border-neutral-700 hover:text-amber-500 hover:border-amber-500/40'
                                }`}
                            >
                                {isEditingMacros ? '[ Done ]' : '[ Edit Macros ]'}
                            </button>
                        </div>
                        
                        {/* Mobile Grid adapts to 1 column to avoid squeezed unreadable text strings */}
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-1.5 my-auto overflow-y-auto pr-1 h-full max-h-[220px] style-scrollbar">
                            {macros.map((macro) => {
                                const isSnapped = snappedId === macro.id;
                                return ( 
                                    <div
                                        key={macro.id}
                                        className={`border p-1.5 flex flex-col justify-between rounded min-h-[80px] transition-colors duration-300 ${activeTheme.border} ${ 
                                            isEditingMacros ? 'bg-amber-500/5 border-amber-500/20' : 'bg-transparent'
                                        }`}
                                    > 
                                        {isEditingMacros ? (
                                            <div className="flex flex-col gap-1.5 h-full justify-between">
                                                <input
                                                    type="text"
                                                    value={macro.name}
                                                    className="bg-neutral-900 border border-neutral-700 px-1 py-0.5 text-[10px] rounded w-full outline-none text-amber-400 font-bold"
                                                    onChange={(e) => {
                                                        const updated = [...macros]; 
                                                        updated[macro.id - 1].name = e.target.value; 
                                                        setMacros(updated); 
                                                    }} 
                                                /> 
                                                <button 
                                                    onClick={() => {
                                                        const updated = [...macros]; 
                                                        updated[macro.id - 1] = { 
                                                            ...macro, 
                                                            robot: { ...stagedRobot }, 
                                                            trap: { ...stagedTrap } 
                                                        }; 
                                                        setMacros(updated); 
                                                        setSnappedId(macro.id); 
                                                        setTimeout(() => setSnappedId(null), 700); 
                                                    }} 
                                                    className={`border text-[8px] text-center py-1 rounded font-bold uppercase tracking-tight transform transition-all duration-200 active:scale-95 ${ 
                                                        isSnapped 
                                                            ? 'bg-emerald-500 border-emerald-400 text-black font-black scale-95 shadow-[0_0_12px_rgba(16,185,129,0.3)]' 
                                                            : 'bg-amber-500/10 hover:bg-amber-500/20 border-amber-500/30 text-amber-500' 
                                                    }`}
                                                > 
                                                    {isSnapped ? '✓ Snapped!' : '📸 Snap Sliders'}
                                                </button>
                                            </div> 
                                        ) : ( 
                                            <button 
                                                disabled={!isAuthenticated} 
                                                className={`w-full h-full text-left focus:outline-none flex flex-col justify-between ${activeTheme.macroHover} ${!isAuthenticated ? 'opacity-40 cursor-not-allowed' : ''}`} 
                                                onClick={() => { 
                                                    setRobotState(macro.robot); 
                                                    setTrapState(macro.trap); 
                                                    setStagedRobot(macro.robot); 
                                                    setStagedTrap(macro.trap); 
                                                    
                                                    if (liveUpdate && jointTopic.current && gripperTopic.current) { 
                                                        jointTopic.current.publish(new ROSLIB.Message({ 
                                                            data: [macro.robot.j1, macro.robot.j2, macro.robot.j3, macro.robot.j4, macro.robot.j5, macro.robot.j6, macro.robot.j7] 
                                                        })); 
                                                        gripperTopic.current.publish(new ROSLIB.Message({ 
                                                            data: JSON.stringify(macro.trap) 
                                                        })); 
                                                    } 
                                                }} 
                                            >
                                                <div className="w-full"> {/* [cite: 89] */}
                                                    <div className="font-bold text-[10px] truncate text-neutral-200">{macro.name}</div> 
                                                    <div className="text-[8px] text-amber-500/90 font-semibold truncate mt-0.5 tracking-tight"> 
                                                        XYZ: {macro.trap.x}, {macro.trap.y}, {macro.trap.z} 
                                                    </div>
                                                    <div className="text-[8px] text-emerald-400/90 font-semibold truncate tracking-tight mt-0.5"> 
                                                        J1-4: {macro.robot.j1}°, {macro.robot.j2}°, {macro.robot.j3}°, {macro.robot.j4}° 
                                                    </div> 
                                                    <div className="text-[8px] text-emerald-400/80 font-semibold truncate tracking-tight"> 
                                                        J5-7: {macro.robot.j5}°, {macro.robot.j6}°, {macro.robot.j7}° 
                                                    </div> {/* [cite: 94] */}
                                                </div>
                                            </button> 
                                        )}
                                    </div> 
                                ); 
                            })}
                        </div> 
                    </div> 
                </div>

                {/* NESTED GRID FOR DESKTOP VIEW ALIGNMENT */}
                <div className="flex-1 h-full flex flex-col min-h-0">
                    
                    {/* TOP VIEW AND DATA LEVEL PANELS */}
                    <div className="flex-1 flex flex-col lg:flex-row lg:h-[65%] min-h-0">
                        
                        {/* 2. CENTER STAGE VISUALIZER */}
                        <div className={`flex-1 h-full flex flex-col relative ${mobileTab !== 'visualizer' ? 'hidden lg:flex' : 'flex'}`}>
                            <div className="absolute top-3 left-3 z-10 flex gap-2">
                                <button onClick={() => setViewMode('model')} className={`px-2 py-0.5 border text-[10px] rounded ${viewMode === 'model' ? 'bg-neutral-800 text-white' : 'bg-transparent'}`}>
                                    Wireframe Canvas 
                                </button> 
                                <button onClick={() => setViewMode('camera')} className={`px-2 py-0.5 border text-[10px] rounded ${viewMode === 'camera' ? 'bg-neutral-800 text-white' : 'bg-transparent'}`}>
                                    PiCam Stream 
                                </button> 
                            </div> 

                            <div className="w-full h-full flex items-center justify-center bg-neutral-500/5 p-6">
                                {viewMode === 'model' ?(
                                    <div className="w-full h-full border border-dashed border-neutral-500/20 rounded flex items-center justify-center relative overflow-hidden">
                                        {cameraFocus === 'arm' ? (
                                            <div className="text-center space-y-3 transition-all duration-500 transform scale-100"> 
                                                <div className="text-[10px] tracking-widest text-neutral-400">// WIREFRAME KINEMATICS GENERATED</div>
                                                <div className="w-24 h-24 border border-neutral-500/30 mx-auto animate-spin relative" style={{ animationDuration: '20s' }}>
                                                    <div className="absolute inset-4 border border-dashed border-neutral-500/20 rotate-45"></div>
                                                </div> 
                                                <div className="text-[9px] text-neutral-500">7DoF Global Matrix Array Loaded</div>
                                            </div> 
                                        ) : ( 
                                            <div className="text-center space-y-2 transition-all duration-500 transform scale-105">
                                                <div className="text-[10px] text-amber-500 tracking-wider font-bold">// MICRO-TRAP FOCUS MATRIX</div>
                                                <div className="w-40 h-40 rounded-full border border-dashed border-neutral-500/30 flex items-center justify-center relative bg-neutral-500/5">
                                                    <div 
                                                        className="absolute w-2.5 h-2.5 bg-white rounded-full shadow-[0_0_10px_#fff] border border-black transition-all duration-200" 
                                                        style={{ 
                                                            transform: `translate(${trapState.x * 3}px, ${-trapState.y * 3}px)` 
                                                        }} 
                                                    /> 
                                                    <div className="w-2 h-2 bg-neutral-500/40 rounded-full absolute"></div> 
                                                </div>
                                                <div className="text-[9px] text-neutral-400">Target Tracking Focal Vector Active</div>
                                            </div>
                                        )}
                                    </div> 
                                ) : ( 
                                    <div className="w-full h-full bg-neutral-950 flex flex-col items-center justify-center text-neutral-500 rounded border border-neutral-800 overflow-hidden relative"> 
                                        <img 
                                            src={`${window.location.protocol}//${window.location.hostname}/video/stream?topic=/camera/circle_detected`} 
                                            alt="ROS 2 Web Video Feed" 
                                            className="w-full h-full object-contain" 
                                            onError={(e) => { 
                                                e.target.onerror = null; 
                                                e.target.src = "https://placehold.co/600x400?text=Camera+Stream+Offline"; 
                                            }} 
                                        /> 
                                        <div className="absolute bottom-2 left-2 bg-black/60 px-2 py-0.5 rounded text-[10px] text-emerald-400 font-bold tracking-wider"> 
                                            📡 LIVE CAMERA PIPE ACTIVE 
                                        </div> 
                                    </div> 
                                )}
                            </div> {/* [cite: 101] */}
                        </div> {/* [cite: 98] */}

                        {/* 3. RIGHT ACOUSTIC COLUMN */}
                        <div className={`w-full lg:w-1/3 h-full flex flex-col border-l ${activeTheme.border} ${mobileTab !== 'acoustic' ? 'hidden lg:flex' : 'flex'}`}> {/* [cite: 118, 119] */}
                            <div className="h-[65%] p-4 border-b border-inherit overflow-y-auto style-scrollbar"> {/* [cite: 119] */}
                                <h2 className="font-bold tracking-wider mb-4 text-neutral-400">// ACOUSTIC FIELD MATRIX</h2> {/* [cite: 119] */}
                                <div className="space-y-4"> {/* [cite: 119] */}
                                    <div className="p-3 bg-neutral-500/5 rounded border border-neutral-700/20 font-bold"> {/* [cite: 120] */}
                                        <div className="text-[9px] text-neutral-400 uppercase tracking-tight mb-1.5">Acoustic Trap Spatial Coordinates</div> {/* [cite: 120] */}
                                        <div className="grid grid-cols-3 gap-1 text-center text-xs"> {/* [cite: 120] */}
                                            <div className="p-1 border bg-neutral-500/10 text-amber-500">X: {trapState.x}</div> {/* [cite: 121] */}
                                            <div className="p-1 border bg-neutral-500/10 text-amber-500">Y: {trapState.y}</div> {/* [cite: 121] */}
                                            <div className="p-1 border bg-neutral-500/10 text-amber-500">Z: {trapState.z}</div> {/* [cite: 122] */}
                                        </div> {/* [cite: 120] */}
                                    </div> {/* [cite: 120] */}
                             
                                    <div className="space-y-2 text-[11px]"> {/* [cite: 123] */}
                                        <div className="flex justify-between border-b border-dashed pb-1 border-neutral-700/20"><span>Array Element Array</span><span>256 Transducers</span></div> {/* [cite: 123] */}
                                        <div className="flex justify-between border-b border-dashed pb-1 border-neutral-700/20"><span>Phase Frequency</span><span>40.0 kHz</span></div> {/* [cite: 124] */}
                                    </div> {/* [cite: 123] */}
                                </div> {/* [cite: 119] */}
                            </div> {/* [cite: 119] */}
                         
                            <div className="h-[35%] hidden lg:block p-4 opacity-50 bg-neutral-500/5 overflow-hidden text-[9px]"> {/* [cite: 125] */}
                                <div>// LIVE SIMULATOR SYSTEM LOG</div> {/* [cite: 125] */}
                                <div className="mt-2 space-y-1"> {/* [cite: 125] */}
                                    <div>[READY] Local offline testing framework ready.</div> {/* [cite: 126] */}
                                    <div>[INFO] Connected to ROS2 bridge instance via roslibjs hooks.</div> {/* [cite: 126] */}
                                </div> {/* [cite: 125] */}
                            </div> {/* [cite: 125] */}
                        </div> {/* [cite: 119] */}

                    </div>

                    {/* 4. BOTTOM INPUT CONTROLLER MATRIX PANEL BAR */}
                    <div className={`w-full lg:h-[35%] border-t p-4 flex flex-col justify-between z-20 ${activeTheme.border} ${activeTheme.panelBg} ${mobileTab !== 'controls' ? 'hidden lg:flex' : 'flex'}`}> {/* [cite: 127, 128] */}
                        
                        <div className="flex flex-wrap items-center justify-between border-b border-neutral-700/20 pb-2 mb-2 gap-3"> {/* [cite: 128] */}
                            <div className="flex items-center gap-4"> {/* [cite: 128] */}
                                <span className="font-bold tracking-wider text-neutral-400 uppercase text-[10px]">Matrix System Controller</span> {/* [cite: 129] */}
                            </div> {/* [cite: 128] */}
                            
                            <div className="flex items-center gap-3"> {/* [cite: 129] */}
                                <label className="flex items-center gap-1.5 cursor-pointer select-none"> {/* [cite: 130] */}
                                    <input 
                                        type="checkbox" 
                                        checked={liveUpdate} 
                                        disabled={!isAuthenticated} 
                                        onChange={(e) => {
                                            setLiveUpdate(e.target.checked); 
                                            if (e.target.checked) { 
                                                setRobotState(stagedRobot); 
                                                setTrapState(stagedTrap); 
                                            } 
                                        }} 
                                        className="accent-neutral-500 rounded" 
                                    /> 
                                    <span className={`font-bold text-[10px] ${liveUpdate ? 'text-emerald-400' : 'text-neutral-500'}`}> 
                                        {liveUpdate ? 'LIVE STREAMING ON' : 'LIVE STREAMING OFF'} 
                                    </span> 
                                </label> 

                                <button 
                                    onClick={handleSendData} 
                                    disabled={!isAuthenticated || liveUpdate} 
                                    className={`px-3 py-1 rounded border font-bold text-[10px] transition-all ${ 
                                        liveUpdate || !isAuthenticated 
                                            ? 'opacity-20 cursor-not-allowed border-neutral-600' 
                                            : 'border-amber-500/60 bg-amber-500/10 hover:bg-amber-500/20 text-amber-500' 
                                    }`}
                                >
                                    Send Data to Pipeline 
                                </button> 
                            </div> 
                        </div> 

                        <div className="flex-1 flex flex-col justify-center overflow-y-auto style-scrollbar"> 
                            {!isAuthenticated ? ( 
                                <div className="text-center p-4 border border-dashed border-amber-500/40 rounded bg-amber-500/5 text-amber-500 font-bold"> 
                                    🔒 INTERLOCK INTERRUPT ACTIVE: Please log in using "123" test credentials to modify parameters. 
                                </div> 
                            ) : ( 
                                <div className="grid grid-cols-1 md:grid-cols-12 gap-3 h-full items-stretch pt-1 pb-1"> 
                                
                                    {/* Section A: 7-Axis Robotic Kinematics Slider Loop */}
                                    <div className={`md:col-span-7 border rounded-lg p-3 bg-neutral-500/5 flex flex-col justify-between ${activeTheme.border}`}> 
                                        <div className="w-full"> 
                                            <div className="text-[9px] uppercase font-bold text-neutral-400 mb-1">// Joint Space Vectors (7DoF Arm)</div> 
                                            
                                            {/* Adapts to 1 column on small phone widths so sliders remain wide and precise */}
                                            <div className="grid grid-cols-1 sm:grid-cols-3 gap-x-3 gap-y-1.5 max-h-[140px] overflow-y-auto pr-1 style-scrollbar"> 
                                                {Object.entries(stagedRobot).map(([joint, val]) => ( 
                                                    <div key={joint} className="space-y-0.5"> 
                                                        <div className="flex justify-between text-[10px]"> 
                                                            <span className="uppercase text-neutral-400 font-semibold">{joint} Angle</span> 
                                                            <span className={liveUpdate ? 'text-emerald-400' : 'text-amber-500 font-bold'}>{val}°</span> 
                                                        </div> 
                                                        <input 
                                                            type="range" min="-180" max="180" step="1" value={val} 
                                                            onChange={e => triggerParamChange('robot', joint, parseInt(e.target.value))} 
                                                            className="w-full h-1 bg-neutral-700/30 rounded appearance-none cursor-pointer accent-neutral-500" 
                                                        /> 
                                                    </div> 
                                                ))}
                                            </div> 
                                        </div> 
                                    </div> 

                                    {/* Section B: Acoustic Trap Space */}
                                    <div className={`md:col-span-5 border rounded-lg p-3 bg-neutral-500/5 flex flex-col ${activeTheme.border}`}>
                                        {/* Header section with Title and Enable/Disable Toggle */}
                                        <div className="flex items-center justify-between mb-3 border-b border-neutral-700/30 pb-2">
                                            <div className="text-[9px] uppercase font-bold text-neutral-400">
                                                // Acoustic Interferometry (Gripper)
                                            </div>
                                            
                                            {/* Trap Enable/Disable Button */}
                                            <button
                                                onClick={() => {
                                                    const currentlyEnabled = stagedTrap['enable'] === 255;
                                                    // Sends 255 (11111111) if turning on, 0 (00000000) if turning off
                                                    triggerParamChange('gripper', 'enable', currentlyEnabled ? 0 : 255);
                                                }}
                                                className={`text-[10px] px-2.5 py-1 rounded font-bold uppercase transition-all duration-200 cursor-pointer ${
                                                    stagedTrap['enable'] === 255 
                                                        ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/30' 
                                                        : 'bg-neutral-800 text-neutral-400 border border-neutral-700/50 hover:bg-neutral-700/50 hover:text-neutral-300'
                                                }`}
                                            >
                                                {stagedTrap['enable'] === 255 ? 'Trap Active' : 'Trap Disabled'}
                                            </button>
                                        </div>

                                        {/* Coordinates Sliders */}
                                        <div className="flex-1 flex flex-col justify-center gap-2.5">
                                            {['x', 'y', 'z'].map((coord) => (
                                                <div key={coord} className="flex items-center gap-3">
                                                    <span className="uppercase text-neutral-400 font-semibold text-[10px] w-12 shrink-0">
                                                        Axis {coord}
                                                    </span>
                                                    <input
                                                        type="range" 
                                                        min="0" 
                                                        max="60" 
                                                        step="0.1" 
                                                        value={stagedTrap[coord] || 0}
                                                        onChange={e => triggerParamChange('gripper', coord, parseFloat(e.target.value))}
                                                        className="flex-1 h-1 bg-neutral-700/30 rounded appearance-none cursor-pointer accent-amber-500"
                                                    />
                                                    <span className={`text-[10px] w-14 text-right shrink-0 font-mono ${liveUpdate ? 'text-emerald-400' : 'text-amber-500 font-bold'}`}>
                                                        {stagedTrap[coord] || 0} mm
                                                    </span>
                                                </div>
                                            ))}
                                        </div>
                                    </div>

                                </div>
                            )}
                        </div> {/* [cite: 143] */}
                    </div> {/* [cite: 128] */}
                    
                </div>

            </div> {/* [cite: 169] */}
        </div>
    ); 
}