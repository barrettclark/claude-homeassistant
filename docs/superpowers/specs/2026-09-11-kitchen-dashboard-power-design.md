# Kitchen Dashboard — Power Sub-Project Design

## Context

Part of the larger kitchen wall-mounted dashboard project (ESP32 touch panel
showing Home Assistant controls + Tempest weather, swipeable pages). The
project is split into three independent sub-projects: firmware/dashboard,
power system (this doc), and case design. This doc covers only the power
system: battery, charging, and how power reaches the board and the PIR
wake sensor.

## Hardware

- **Display board**: DIYmalls / Sunton ESP32-8048S043C — ESP32-S3-WROOM-1-N16R8,
  4.3" 800x480 RGB parallel display, GT911 capacitive touch.
- **Wake sensor**: HC-SR501 PIR motion module (WWZMDiB, HC-SR501-compatible).

### Confirmed board facts (researched, not assumed)

- No onboard LiPo charging circuit and no battery connector — this board is
  USB-power-only out of the box.
- Power input is 5V, accepted either via the USB-C port or directly on the
  5V pin broken out on the P1/P4 headers (same rail).
- Only two exposed GPIO pins are free of any boot-strapping/peripheral duty:
  **GPIO17** and **GPIO18**. Every other exposed pin is consumed by the RGB
  display bus, GT911 touch I2C (GPIO19/20), SPI/microSD (GPIO11-13), or UART
  (GPIO43/44).
- Backlight is PWM-controlled on GPIO2 (already used internally by the
  display driver — not available for other use).
- HC-SR501 requires 4.5–20V to operate; it cannot run off the board's 3.3V
  rail or directly off a 3.7V LiPo cell.

## Decision: 3x AA NiMH + plain boost converter (no charging circuit)

Rather than an onboard LiPo + charge/boost IC, power comes from **3x AA
NiMH rechargeable cells** (~4.5V fresh, ~3.6-4.2V through most of the
discharge curve — always at or below the 5V target) feeding a **plain
boost-only converter** (MT3608-class) that steps up to a regulated 5V.
There is no charging circuit in the device at all: depleted cells are
pulled from the case and recharged externally in a standard AA charger,
then swapped back in.

This was chosen over a rechargeable-in-place LiPo design after two rounds
of sourcing problems with LiPo charge/boost modules:

### Alternatives considered and rejected

| Approach | Rejected because |
|---|---|
| LiPo + combined IP5306-class charger/boost module | IP5306 (the common chip in these modules) is designed to mimic a phone power bank: it auto-shuts-down its 5V output when load current drops below ~45-50mA for ~32 seconds, to detect "no device connected." During PIR light-sleep, standby draw can easily sit under that threshold — the board could silently lose power and never wake. The "CK" variant of the chip doesn't have this behavior, but Amazon listings don't reliably disclose which chip variant is on the board, and the one confirmed-CK source we found (circuitcomps.com) was out of stock. |
| Separate TP4056 charger + separate MT3608 boost | TP4056 alone has no load-sharing — can't safely charge and power the load at the same time. |
| Off-the-shelf USB power bank as the internal battery | Same auto-shutoff-under-light-load problem as the IP5306 module above — power banks are built on the same class of chip. |
| 9V battery + buck converter | 9V primary cells have high internal resistance and low capacity (~500-600mAh alkaline, ~1200mAh lithium) and aren't rated for the ~400-500mA bursts the display draws when active — real risk of brownout during exactly the moments the display needs to be responsive. |
| 3x AAA instead of AA | Same circuit, smaller case footprint, but roughly half the capacity (~800-1200mAh vs ~1900-3000mAh) — less margin against the 3-5 day runtime target. |

The MT3608 boost converter was specifically checked against the same
auto-shutoff concern: at light loads it shifts into a lower-efficiency
pulse-frequency-modulation switching mode, but it does not cut output
entirely the way IP5306 does. Safe for this use case.

## Bill of materials

| Part | Spec | Notes |
|---|---|---|
| Battery cells | 3x AA NiMH rechargeable, 2800mAh (purchased: 4-pack with charger) | 4 cells is only one spare, not a full spare set of 3 — for true swap-without-waiting, buy a second 3+ pack so a full charged set is always ready |
| Battery holder | 3x AA holder, wire-lead output, with inline ON/OFF switch (purchased: Goweewon 2-pack) | Mounted inside the case; switch gives a hard power cutoff for handling/storage. Second holder in the pack is a spare |
| Boost converter | MT3608-based module, adjustable 5V-28V output, 2A rating, 2-24V input (purchased: Ferwooh 5-pack, bare solder-pad I/O) | Confirmed no auto-shutoff-under-light-load behavior (see above). **Must trim the onboard potentiometer to exactly 5.0V (verify with multimeter) before wiring to the ESP32 board or PIR** — ships set to an arbitrary voltage that can exceed 5V and damage the board. Spares in the pack cover mis-trims |
| PIR sensor | HC-SR501-compatible (already ordered — WWZMDiB 5-pack) | Requires 4.5-20V supply, fed from the boosted 5V rail |
| JST-1.25mm-to-Dupont pigtail cables (single/double/quad) and bare hookup wire | Both on hand | Used to tap the board's two back headers (power pins + GPIO17) — only one 4-pin pigtail ships with the board. Prefer soldering bare wire directly to the header pads for the permanent wall-mounted connections (won't work loose over time); reserve the pigtail cables for anything you might want serviceable/unpluggable later |

## Wiring

```
3x AA holder (+/-) ──> Boost converter IN
                        Boost converter 5V OUT ──┬──> ESP32 board 5V pin (P1/P4 header)
                                                  └──> PIR VCC
                        Boost converter GND ──┬──> ESP32 board GND
                                               └──> PIR GND
                        PIR OUT (digital) ────────> ESP32 GPIO17
```

- GPIO17 chosen for the PIR signal since it's one of only two pins on this
  board with no boot-strapping or peripheral conflict (the other, GPIO18,
  is held in reserve for future use).
- The board's own onboard USB-C (used for initial firmware flashing) does
  not need to be exposed through the case — it's only needed during setup
  and can be reached by opening the case.
- No exterior charging port is needed on the case at all, since there's no
  onboard charging circuit — the case instead needs a battery access
  hatch for pulling the 3 AA cells out to recharge (see case sub-project).

## Sleep strategy (drives runtime, owned in detail by the firmware spec)

**Light sleep**, not deep sleep, on PIR wake (GPIO17 as wake source):

- Deep sleep would clear RAM on every wake, forcing a multi-second reboot +
  WiFi reconnect on every PIR trigger — unacceptable for a "walk up and it's
  already responsive" dashboard.
- Light sleep gates clocks but preserves RAM/WiFi state, trading a somewhat
  higher standby current for near-instant wake. Given the PIR itself draws
  continuous current regardless of sleep depth, the light-sleep power
  penalty is not the dominant factor in runtime.

## Runtime target

3-5 days between battery swaps. Not yet backed by measured current draw
(no published power consumption specs found for this board) — to be
validated once the firmware is running by measuring actual sleep/active
current with a USB power meter, and adjusted (spare-set rotation frequency
or sleep strategy) if the measured numbers miss the target.

## Open items carried to other sub-projects

- **Case spec** needs: a battery access hatch sized for the 3x AA holder
  (no exterior charging port required, since there's no onboard charging
  circuit), room for the MT3608 boost module, and PIR sensor placement/bore
  facing the room.
- **Firmware spec** needs: light-sleep implementation with GPIO17 ext-wake,
  and validating actual current draw against the 3-5 day target.
