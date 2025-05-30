/*
This extension exports Tiled map level data as Assembly (6502) data format in single file $(fileName.asm) 
later that can be imported in your project directly by including that file.
Extension : Export Assembly data. 
Author: Joris de Jong
Tool: Tiled (1.11.2)
Copyleft@ 2025

Usage: 
1)Place this file in your extensions folder.
2)Open your map in Tiled editor and export data (File -> Export -> Export As -> Assembly (6502) format)
3)Save your file. 

Extensions folder path for different OS.
Windows     C:/Users/<USER>/AppData/Local/Tiled/extensions/
macOS       ~/Library/Preferences/Tiled/extensions/
Linux       ~/.config/tiled/extensions/
*/

const NAMETABLEWIDTH = 32;
const NAMETABLEHEIGHT = 30;

//Method to export multi-map (Map with multiple rooms)
function multiMapExportAsm(filePath, map) {
  //Setting absolute file path and name.
  var fileNameExt = filePath.replace(/^.*[\\\/]/, "");
  var fileName = fileNameExt.split(".").slice(0, -1).join(".");

  var file = new TextFile(filePath, TextFile.WriteOnly);

  //Writing export header .
  var exportHeader =
    ";File: '" +
    fileNameExt +
    "\n" +
    ";Map Type: Multi Room [width: " +
    map.width +
    ",height: " +
    map.height +
    "] " +
    "\n" +
    ";Exported: Using Tiled(Assembly 6502) plugin by Joris de Jong\n" +
    "\n";
  file.write(exportHeader);

  // Get the amount of rooms
  var hLoop = map.width / NAMETABLEWIDTH;
  var vLoop = map.height / NAMETABLEHEIGHT;
  var loops = vLoop == 1 && hLoop == 1 ? 1 : vLoop + hLoop;

  //Writing export data.
  for (var l = 0; l < map.layerCount; ++l) {
    var layer = map.layerAt(l);
    if (layer.isTileLayer) {
      for (let room = 0; room < loops; room++) {
        file.write(fileName + "_" + room + ":\n.byte ");
        for (var v = 0; v < vLoop; v++) {
          for (let h = 0; h < hLoop; h++) {
            for (let y = 0; y < NAMETABLEHEIGHT; y++) {
              for (let x = 0; x < NAMETABLEWIDTH; x++) {
                currentX = h * NAMETABLEWIDTH + x;
                currentY = v * NAMETABLEHEIGHT + y;
                file.write("$" + layer.cellAt(currentX, currentY).tileId);
                file.write(x < NAMETABLEWIDTH - 1 ? "," : "");
              }
              if (y != NAMETABLEHEIGHT - 1) {
                file.write("\n.byte ");
              }
            }
          }
          file.write("\n\n");
        }
      }
    }
  }

  //Adding data to list.
  file.write(fileName + "_list:\n.addr ");
  for (var i = 0; i < loops; ++i) {
    file.write(fileName + "_" + i);
    if (loops > 1 && i < loops - 1) file.write(",");
  }
  file.write("\n");
  tiled.alert("Exporting data finished");
  file.commit();
}

//Main Export method.
var asmExportFormat = {
  name: "Assembly format (6502)",
  extension: "asm",

  write: function (map, filePath) {
    //Check map properties.
    if (map.width < 16) {
      tiled.alert("File too small to handle.", "Export error");
      return;
    }

    if ((map.width & 0x0f) != 0)
      tiled.alert("Warning expected width divisible by 16.");

    multiMapExportAsm(filePath, map);
  },
};

tiled.registerMapFormat("Assembly format (6502)", asmExportFormat);
