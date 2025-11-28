#fix iommu error

#!/bin/bash
nano /etc/defult/grub 

#replace the line

#GRUB_CMDLINE_LINUX_DEFAULT="quiet"

#with 

#GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"

update-grub
reboot
