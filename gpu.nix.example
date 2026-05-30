{ pkgs, ... }: {
	hardware.graphics.enable = true;
	hardware.graphics.extraPackages = [
		pkgs.intel-media-driver
		pkgs.libvdpau-va-gl
	];
	hardware.cpu.intel.updateMicrocode = true;
}
