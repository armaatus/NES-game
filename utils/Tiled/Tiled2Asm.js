/*
This extension exports Tiled map level data as Assembly (6502) data format in single file $(fileName.asm) 
later that can be imported in your project directly by including that file.
Extension : Export Assembly data. 
Author: Joris de Jong
Tool: Tiled (1.11.5)
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

const NAMETABLE_WIDTH = 32;
const NAMETABLE_HEIGHT = 30;
const RLE_ENABLED = true;

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
  var hLoop = map.width / NAMETABLE_WIDTH;
  var vLoop = map.height / NAMETABLE_HEIGHT;
  var loops = vLoop == 1 && hLoop == 1 ? 1 : vLoop + hLoop;

  //Writing export data.
  for (var l = 0; l < map.layerCount; ++l) {
    var layer = map.layerAt(l);
    if (layer.isTileLayer) {
      for (let room = 0; room < loops; room++) {
        file.write(fileName + "_" + room + ":\n.byte ");
        for (var v = 0; v < vLoop; v++) {
          for (let h = 0; h < hLoop; h++) {
            for (let y = 0; y < NAMETABLE_HEIGHT; y++) {
              let tilesOnX = [];
              for (let x = 0; x < NAMETABLE_WIDTH; x++) {
                currentX = h * NAMETABLE_WIDTH + x;
                currentY = v * NAMETABLE_HEIGHT + y;
                let currentTileId = layer.cellAt(currentX, currentY).tileId;
                if (RLE_ENABLED) {
                  // Use RLE compression
                  tilesOnX.push(currentTileId);
                } else {
                  // Just print every tile on each location
                  file.write(`${decToHex(currentTileId)}`);
                  file.write(x < NAMETABLE_WIDTH - 1 ? "," : "");
                }
              }
              if (RLE_ENABLED) {
                RLECompression(tilesOnX, file, y);
              } else if (y != NAMETABLE_HEIGHT - 1) {
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

// RLE
function RLECompression(values, file, y) {
  // Catch if values has length of one
  if (values.length == 1) {
    file.write(`$01,$${decToHex(values[0])}`);
    return;
  }

  let currentValue = values[0];
  let currentCount = 1;
  for (let i = 1; i < values.length; i++) {
    const element = values[i];

    if (currentValue != element) {
      file.write(`${decToHex(currentCount)},`);
      file.write(`${decToHex(currentValue)},  `);

      // Set it to the new values
      currentCount = 0;
      currentValue = element;
    }

    // End of the list catch
    if (i == values.length - 1) {
      currentCount++;
      file.write(`${decToHex(currentCount)},`);
      file.write(`${decToHex(currentValue)}`);
      if (y != NAMETABLE_HEIGHT - 1) {
        file.write("\n.byte ");
      }
      return;
    }

    currentCount++;
  }
}

function decToHex(number) {
  return `$${number < 16 ? "0" : ""}${number.toString(16)}`;
}

//Main Export method.
var asmExportFormat = {
  name: "Assembly format (6502)",
  extension: "asm",

  write: function (map, filePath) {
    //Check map properties.
    if (map.width < 32) {
      tiled.alert("File too small to handle.", "Export error");
      return;
    }

    if ((map.width & 0x1f) != 0)
      tiled.alert("Warning expected width divisible by 32.");

    multiMapExportAsm(filePath, map);
  },
};

tiled.registerMapFormat("Assembly format (6502)", asmExportFormat);
