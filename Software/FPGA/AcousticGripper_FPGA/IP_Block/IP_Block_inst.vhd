	component IP_Block is
		port (
			probe : in std_logic_vector(65 downto 0) := (others => 'X')  -- probe
		);
	end component IP_Block;

	u0 : component IP_Block
		port map (
			probe => CONNECTED_TO_probe  -- probes.probe
		);

