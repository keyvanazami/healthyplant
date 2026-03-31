# Print Settings — HealthyPlant Sensor Enclosure

## Material
- **PETG** (recommended) — UV resistant, slight flex for snap-fit joints
- ASA is also suitable for outdoor use (better UV resistance)
- PLA works for indoor-only sensors but will warp in heat/sun

## Slicer Settings
| Setting | Value |
|---------|-------|
| Layer height | 0.2mm |
| Infill | 20% gyroid |
| Walls/perimeters | 3 |
| Top/bottom layers | 4 |
| Supports | Yes (for USB-C port overhang only) |
| Support type | Tree or normal, touching buildplate only |
| Brim | 3mm (for stake piece) |

## Print Orientation
- **Main body**: Upright (open top facing up) — no supports needed except USB port
- **Lid**: Flat, ventilation side up
- **Stake**: Vertical (pointed tip down) — add brim for adhesion
- **Battery tray**: Flat on build plate

## Estimated Print Times (per piece)
| Part | Time | Filament |
|------|------|----------|
| Main body | ~1.5 hr | ~25g |
| Lid | ~30 min | ~10g |
| Stake | ~40 min | ~12g |
| Battery tray | ~20 min | ~5g |
| **Total** | **~3 hr** | **~52g** |

## Generating STL Files
Requires OpenSCAD installed (`brew install openscad`):

```bash
cd hardware/enclosure
openscad -o main_body.stl -D 'part="body"' healthyplant-sensor.scad
openscad -o lid.stl -D 'part="lid"' healthyplant-sensor.scad
openscad -o stake.stl -D 'part="stake"' healthyplant-sensor.scad
openscad -o battery_tray.stl -D 'part="battery"' healthyplant-sensor.scad
```

## Post-Print
1. Remove supports from USB-C port opening
2. Test snap-fit lid — should click firmly but be removable by hand
3. For outdoor use: apply silicone sealant around USB-C gasket area
4. Thread soil moisture probe + DS18B20 cable through the stake's wire channel
