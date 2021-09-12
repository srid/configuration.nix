all:
	sudo nixos-rebuild switch -j auto && systemctl restart --user emanote

home:
	nix build ".#homeConfigurations."`whoami`@`hostname`".activationPackage"
	
	
freeupboot:
	# Delete all but the last few generations
	sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +5
	sudo nixos-rebuild boot
