# Artix Linux ISO-builder

A customizable script for building an ISO that automatically executes an install-script at boot - the script is fetched from one of my other projects, but can point to any other git-repo.

By default the init is dinit, albeit that's only due to it's fast initialization, while only basics and neccessary toolkits - such as NetworkManager for easy setting up a network-connection - is installed onto the ISO; any other packages can be added to artools-workspace/iso-profiles/common/Packages-base.

## Installation

Any missing dependencies will be installed automatically, though the path to the answerfile must be provided, if one wishes to automatic install Artix Linux onto an partition right from boot:
```bash
git clone https://gitlab.com/FabseGP02/artix-linux-iso-maker.git
cd artix-linux-iso-maker
chmod u+x ISO_maker.sh
./ISO_maker.sh # Remember to replace the answerfile, if an automatic install is desired
````

Be aware that no prompts is provided.

## TODO
In no given order:

- [ ] Implementing minor prompts - such as package selection or choosing git-repo
- [ ] Replace mkinitcpio for booster, which generates initramfs considerably faster 


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[GPL](https://choosealicense.com/licenses/gpl-3.0/)
