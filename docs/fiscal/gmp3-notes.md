# GMP3 Pairing Notes (INPOS M530)

Source: `docs/references/gmp3-esleme-protokolu-dokumani.pdf`

## Prerequisites
- Device and POS are on the same LAN.
- Static IP recommended for the fiscal device.
- Know the device IP and the port used for GMP3.
- Ensure any firewall allows TCP traffic between POS and device.

## Pairing steps (device UI)
1) On INPOS M530: open **Harici Uygulamalar** (External Apps).
2) Choose **Uygulama Esle** (Pair Application).
3) Enter application number (AppNo) assigned for the POS adapter.
4) Enter the POS adapter IP and port.
5) Confirm pairing and note any pairing code or confirmation output.

## Adapter architecture (planned)
POS (ERPNext/POS Awesome)
  -> fiscal-adapter (LAN service)
    -> INPOS M530 over Ethernet (GMP3)

Fallback strategy:
- If adapter fails or is unavailable, cashier prints fiscal receipt manually on the device.

## TODO
- Implement GMP3 message framing, checksum, and acknowledgements.
- Handle device error codes and retries.
- Implement online/offline and timeout behavior.
- Confirm required ports and final pairing flow in the PDF.