packer {
  required_plugins {
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
    virtualbox = {
      version = "~> 1.0.5"
      source  = "github.com/hashicorp/virtualbox"
    }
    windows-update = {
      version = "0.15.0"
      source  = "github.com/rgl/windows-update"
    }
  }
}

variable "winrm_username" {
  type        = string
  description = "winrm username"
  default     = "vagrant"
}

variable "winrm_password" {
  type        = string
  description = "winrm password"
  default     = "vagrant"
}

source "virtualbox-iso" "win11" {
  #iso_url      = "iso/tiny11.iso"
  #iso_checksum = "68f1fd12e81be3d7221128e598f056ce8de8e455"
  boot_command         = ["a<wait>a<wait>a"]
  boot_wait            = "-1s"
  cd_files             = ["${path.root}/setup/*"]
  cd_label             = "cd"
  cpus                 = 2
  memory               = 4096
  disk_size            = 262144
  hard_drive_interface = "sata"
  firmware             = "efi"
  guest_additions_mode = "disable"
  guest_os_type        = "Windows11_64"
  headless             = false
  iso_url              = "image/win11.iso"
  iso_checksum         = "174927a61f0026291198a63e588a44bc76ed9f15"
  output_directory     = "win11"
  vm_name              = "win11"
  communicator         = "winrm"
  winrm_password       = "vagrant"
  winrm_timeout        = "6h"
  winrm_port           = "5985"
  winrm_insecure       = true
  winrm_username       = "vagrant"
  shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
}

build {
  sources = ["source.virtualbox-iso.win11"]

  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    scripts           = ["./setup/disable-screensaver.ps1"]
  }

  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    scripts           = ["./setup/microsoft-updates.ps1"]
  }

  provisioner "windows-update" {
    pause_before    = "30s"
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*VMware*'",
      "exclude:$_.Title -like '*Preview*'",
      "exclude:$_.InstallationBehavior.CanRequestUserInput",
      "include:$true"
    ]
    restart_timeout = "120m"
  }

  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    scripts           = ["./setup/choco-pkgs.ps1"]
  }

  provisioner "powershell" {
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
    scripts           = ["./setup/fixnetwork.ps1"]
  }

  post-processor "vagrant" {
    keep_input_artifact  = false
    output               = "output_directory/win11_{{ .Provider}}.box"
    vagrantfile_template = "vagrantfile-win11.template"
  }
}
