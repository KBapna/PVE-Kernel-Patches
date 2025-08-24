# PVE-Kernel Patches for 6.8.12-13

This repository provides custom patches and an automated build system for compiling a modified Proxmox VE (PVE) kernel version 6.8.12-13. These patches aim to enhance virtual machine behavior, improve stealth against detection methods, and apply performance optimizations.


## Included Patches

### 1. RDTSC Clamp/Scaling Patch (Optional / Experimental)

This patch intercepts guest `RDTSC` and `RDTSCP` instructions to synthesize smoother, monotonic TSC values. It is designed to mitigate timing-based detection methods used by software running inside virtual machines.

#### What it does:
- Intercepts `RDTSC`, `RDTSCP`, `UMWAIT`, and `TPAUSE` VM exits
- Applies pseudo-random clamping to reduce detectable TSC deltas
- Introduces configurable noise to simulate natural CPU timing jitter
- Handles ramp-up behavior when host delta increases to keep guest TSC realistic

#### Tunable Parameters (boot-time or runtime via sysfs):
```
rdtsc_clamp_threshold  = 10240    # Host delta threshold
rdtsc_clamp_min_inc    = 32       # Minimum increment on clamp
rdtsc_clamp_max_inc    = 2048     # Maximum clamped increment
rdtsc_clamp_noise_mask = 0xFF     # Bitmask for TSC noise

base_inc = rdtsc_clamp_min_inc * 24 + noise; // 24 multiplier helps mitigate Locky detection trick
```

Example:
```bash
echo 64 > /sys/module/kvm/parameters/rdtsc_clamp_min_inc
```

> **Warning:** This patch is functional but may cause detection in specific edge cases. Tuning is required for optimal results and may still induce detection. This patch is **disabled by default** in the build script.


### 2. Hypervisor Interception/Trap Patch (Avoids TF+DR0 Detection Trick) For Intel

This patch improves the logic in `kvm_vcpu_do_singlestep()` to defeat Intel-specific trap detection techniques based on simultaneous use of the Trap Flag (TF) and hardware breakpoints (DR0-DR3). 

#### What it does:
- Correctly accumulates DR6 flags when both TF and DR0 are triggered
- Ensures both `DR6.BS` and `DR6.B0` are set when appropriate
- Forces a `KVM_EXIT_DEBUG` to userspace when detection logic expects both sources of traps to fire
- Defeats detection logic that relies on incorrect DR6 bits (e.g., when hypervisors prioritize DR0 only)

This patch effectively prevents the following trap-based detection technique:

> **Intel detection trick**: When both a hardware breakpoint (DR0) and TF are active, Intel CPUs set both `DR6.BS` and `DR6.B0`. Hypervisors that mishandle this (e.g., only firing DR0 or clearing TF) expose themselves to detection. This patch ensures proper emulation.

This patch is **stable** and applied by default.


### 3. Linux-TKG Mega Patch (Performance & Gaming Optimizations)

The full Linux TKG patchset is integrated into the kernel build to enhance responsiveness and modified to fix build errors.

#### Included Enhancements:
- Custom CPU scheduler support (MuQSS, BMQ, EEVDF variants)
- `fsync` and `futex2` support for Wine/Proton compatibility
- IOMMU and ACS override patches for better PCI passthrough support
- Kernel optimization flags and build tweaks
- Distro compatibility patches
- RGB driver compatibility for OpenRGB

#### Included TKG Patch Files:
```
0001-add-sysctl-to-disallow-unprivileged-CLONE_NEWUSER-by.patch
0001-bore.patch
0002-clear-patches.patch
0003-glitched-base.patch
0003-glitched-cfs.patch
0003-glitched-eevdf-additions.patch
0005-glitched-pds.patch
0006-add-acs-overrides_iommu.patch
0007-v6.8-fsync1_via_futex_waitv.patch
0007-v6.8-ntsync.patch
0009-glitched-bmq.patch
0009-glitched-ondemand-bmq.patch
0009-prjc.patch
0012-misc-additions.patch
0013-fedora-rpm.patch
0013-gentoo-kconfig.patch
0013-gentoo-print-loaded-firmware.patch
0013-optimize_harder_O3.patch
0013-suse-additions.patch
0014-OpenRGB.patch
```

Source:  
https://github.com/Frogging-Family/linux-tkg/tree/master/linux-tkg-patches/6.8

This patchset is **safe**, **stable**, and **applied by default** in the build script.


## Automated Kernel Build

The included `build.sh` script automates:

- Downloading the official PVE kernel source for version 6.8.12-13
- Applying the Linux TKG and Trap patches automatically
- Optionally applying the RDTSC patch (commented out by default)
- Compiling the patched kernel and packaging `.deb` files

### Usage:
```bash
git clone https://github.com/KBapna/PVE-Kernel-Patches/
cd PVE-Kernel-Patches
chmod +x build.sh
./build.sh
```

To enable the RDTSC patch, edit `build.sh` and uncomment the relevant patch line.


## Patch Stability

| Patch               | Status       | Notes                                  |
|---------------------|--------------|----------------------------------------|
| RDTSC Clamp Patch   | Experimental | Requires tuning, may trigger detection |
| Trap Patch          | Stable       | Avoids TF+DR0 detection reliably       |
| Linux TKG Patch     | Stable       | Performance-focused, production-safe   |


## Credits

- Frogging-Family: https://github.com/Frogging-Family/linux-tkg
- Proxmox and KVM developers
