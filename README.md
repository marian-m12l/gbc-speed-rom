```
rgbasm -o speed.o speed.asm && rgblink -o speed.gbc -m speed.map -n speed.sym speed.o && rgbfix -v -m 0x01 -c -p 0 speed.gbc
```