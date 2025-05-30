// NES color palette (2C02 PPU) - complete 64 color palette
const NES_PALETTE = [
  // 0x00-0x0F
  [124, 124, 124],
  [0, 0, 252],
  [0, 0, 188],
  [68, 40, 188],
  [148, 0, 132],
  [168, 0, 32],
  [168, 16, 0],
  [136, 20, 0],
  [80, 48, 0],
  [0, 120, 0],
  [0, 104, 0],
  [0, 88, 0],
  [0, 64, 88],
  [0, 0, 0],
  [0, 0, 0],
  [0, 0, 0],
  // 0x10-0x1F
  [188, 188, 188],
  [0, 120, 248],
  [0, 88, 248],
  [104, 68, 252],
  [216, 0, 204],
  [228, 0, 88],
  [248, 56, 0],
  [228, 92, 16],
  [172, 124, 0],
  [0, 184, 0],
  [0, 168, 0],
  [0, 168, 68],
  [0, 136, 136],
  [0, 0, 0],
  [0, 0, 0],
  [0, 0, 0],
  // 0x20-0x2F
  [248, 248, 248],
  [60, 188, 252],
  [104, 136, 252],
  [152, 120, 248],
  [248, 120, 248],
  [248, 88, 152],
  [248, 120, 88],
  [252, 160, 68],
  [248, 184, 0],
  [184, 248, 24],
  [88, 216, 84],
  [88, 248, 152],
  [0, 232, 216],
  [120, 120, 120],
  [0, 0, 0],
  [0, 0, 0],
  // 0x30-0x3F
  [252, 252, 252],
  [164, 228, 252],
  [184, 184, 248],
  [216, 184, 248],
  [248, 184, 248],
  [248, 164, 192],
  [240, 208, 176],
  [252, 224, 168],
  [248, 216, 120],
  [216, 248, 120],
  [184, 248, 184],
  [184, 248, 216],
  [0, 252, 252],
  [248, 216, 248],
  [0, 0, 0],
  [0, 0, 0],
];

// Color names for better debugging
const COLOR_NAMES = {
  "0,0,0": "Black",
  "124,124,124": "Dark Gray",
  "188,188,188": "Light Gray",
  "248,248,248": "White",
  "252,252,252": "Bright White",
  "0,0,252": "Blue",
  "0,0,188": "Dark Blue",
  "0,88,248": "Medium Blue",
  "0,120,248": "Light Blue",
  "60,188,252": "Sky Blue",
  "104,136,252": "Pale Blue",
  "164,228,252": "Lightest Blue",
  "184,184,248": "Pale Purple Blue",
  "0,232,216": "Cyan",
  "0,252,252": "Bright Cyan",
  "0,136,136": "Teal",
  "0,64,88": "Dark Teal",
  "0,168,68": "Sea Green",
  "0,184,0": "Green",
  "0,168,0": "Dark Green",
  "0,120,0": "Darker Green",
  "0,104,0": "Darkest Green",
  "0,88,0": "Forest Green",
  "88,216,84": "Light Green",
  "184,248,24": "Yellow Green",
  "88,248,152": "Mint Green",
  "184,248,184": "Pale Green",
  "216,248,120": "Light Yellow Green",
  "184,248,216": "Pale Mint",
  "248,184,0": "Orange",
  "252,160,68": "Light Orange",
  "248,56,0": "Red Orange",
  "228,0,88": "Red",
  "168,0,32": "Dark Red",
  "168,16,0": "Brown Red",
  "136,20,0": "Brown",
  "80,48,0": "Dark Brown",
  "172,124,0": "Gold",
  "228,92,16": "Dark Orange",
  "248,88,152": "Pink",
  "248,120,248": "Magenta",
  "216,0,204": "Purple",
  "148,0,132": "Dark Purple",
  "68,40,188": "Indigo",
  "104,68,252": "Light Purple",
  "152,120,248": "Lavender",
  "216,184,248": "Light Lavender",
  "248,184,248": "Pink Lavender",
  "248,164,192": "Light Pink",
  "240,208,176": "Peach",
  "252,224,168": "Light Peach",
  "248,216,120": "Pale Yellow",
  "248,120,88": "Salmon",
  "248,216,248": "Pale Pink",
  "120,120,120": "Gray",
};

let tilePalettes = [];
let globalColorUsage = {};
let sharedPalette = null;
let globalBackgroundColor = null; // Track the global background color

// Initialize NES palette display
function initializeNESPalette() {
  const grid = document.getElementById("nesPaletteGrid");
  grid.innerHTML = "";

  for (let i = 0; i < NES_PALETTE.length; i++) {
    const color = NES_PALETTE[i];
    const cell = document.createElement("div");
    cell.className = "nes-color-cell";
    cell.style.backgroundColor = `rgb(${color[0]}, ${color[1]}, ${color[2]})`;

    const index = document.createElement("div");
    index.className = "nes-color-index";
    index.textContent = i.toString(16).toUpperCase().padStart(2, "0");
    cell.appendChild(index);

    // Add hover tooltip
    cell.addEventListener("mouseenter", (e) => {
      const tooltip = document.getElementById("colorTooltip");
      const name = getColorName(color);
      const hex = i.toString(16).toUpperCase().padStart(2, "0");
      tooltip.innerHTML = `$${hex}: ${name}<br>RGB(${color.join(", ")})`;
      tooltip.style.display = "block";
    });

    cell.addEventListener("mousemove", (e) => {
      const tooltip = document.getElementById("colorTooltip");
      tooltip.style.left = e.pageX + 10 + "px";
      tooltip.style.top = e.pageY - 40 + "px";
    });

    cell.addEventListener("mouseleave", () => {
      document.getElementById("colorTooltip").style.display = "none";
    });

    grid.appendChild(cell);
  }
}

function getNESColorIndex(color) {
  for (let i = 0; i < NES_PALETTE.length; i++) {
    if (
      NES_PALETTE[i][0] === color[0] &&
      NES_PALETTE[i][1] === color[1] &&
      NES_PALETTE[i][2] === color[2]
    ) {
      let output = i.toString(16).toUpperCase().padStart(2, "0");
      return output !== "0D" ? output : "0F";
    }
  }
  return "??";
}

function getColorName(color) {
  const key = color.join(",");
  return COLOR_NAMES[key] || `RGB(${key})`;
}

document
  .getElementById("fileInput")
  .addEventListener("change", handleFileUpload);

function handleFileUpload(e) {
  const file = e.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = function (event) {
    const img = new Image();
    img.onload = function () {
      processImage(img);
    };
    img.src = event.target.result;
  };
  reader.readAsDataURL(file);
}

function processImage(img) {
  // Validate image dimensions
  if (
    !(
      (img.width === 128 && img.height === 128) ||
      (img.width === 128 && img.height === 256)
    )
  ) {
    alert(
      "Error: Image must be exactly 128x128 or 128x256 pixels for CHR conversion tools!",
    );
    return;
  }

  const originalCanvas = document.getElementById("originalCanvas");
  const convertedCanvas = document.getElementById("convertedCanvas");
  const sharedPaletteCanvas = document.getElementById("sharedPaletteCanvas");

  // Set canvas sizes
  originalCanvas.width =
    convertedCanvas.width =
    sharedPaletteCanvas.width =
      img.width;
  originalCanvas.height =
    convertedCanvas.height =
    sharedPaletteCanvas.height =
      img.height;

  // Draw original
  const originalCtx = originalCanvas.getContext("2d");
  originalCtx.drawImage(img, 0, 0);

  // Process tiles
  const imageData = originalCtx.getImageData(0, 0, img.width, img.height);
  const convertedData = new ImageData(img.width, img.height);
  const sharedPaletteData = new ImageData(img.width, img.height);

  tilePalettes = [];
  globalColorUsage = {};

  // Process each 8x8 tile
  const tilesX = Math.floor(img.width / 8);
  const tilesY = Math.floor(img.height / 8);

  // First pass: analyze all tiles and build color usage stats
  let tileIndex = 0;
  for (let ty = 0; ty < tilesY; ty++) {
    for (let tx = 0; tx < tilesX; tx++) {
      // Skip empty tiles
      if (isTileEmpty(imageData, tx * 8, ty * 8)) {
        tileIndex++;
        continue;
      }

      const tile = extractTile(imageData, tx * 8, ty * 8);
      const nesColoredTile = tile.map((color) => findClosestNESColor(color));

      // Count global color usage
      nesColoredTile.forEach((color) => {
        const key = color.join(",");
        globalColorUsage[key] = (globalColorUsage[key] || 0) + 1;
      });
    }
  }

  // Generate shared palette from most used colors
  sharedPalette = generateSharedPalette(globalColorUsage);

  // Set the global background color (most common color across all tiles)
  globalBackgroundColor = sharedPalette[0];

  // Second pass: generate individual palettes and apply conversions
  tileIndex = 0;
  for (let ty = 0; ty < tilesY; ty++) {
    for (let tx = 0; tx < tilesX; tx++) {
      // Skip empty tiles but maintain index
      if (isTileEmpty(imageData, tx * 8, ty * 8)) {
        tileIndex++;
        continue;
      }

      const tile = extractTile(imageData, tx * 8, ty * 8);

      // Generate two palettes:
      // 1. Individual palette (each tile picks its own 4 colors)
      const individualPalette = generateTilePalette(tile);

      // 2. Palette with shared background color
      const paletteWithSharedBg = generateTilePaletteWithBackground(
        tile,
        globalBackgroundColor,
      );

      tilePalettes.push({
        x: tx,
        y: ty,
        index: tileIndex,
        palette: individualPalette,
        paletteWithSharedBg: paletteWithSharedBg,
      });

      // Apply individual palette to tile
      applyIndividualPaletteToTile(
        imageData,
        convertedData,
        tx * 8,
        ty * 8,
        individualPalette,
      );

      // Apply shared palette remapping to tile (using shared background)
      applySharedPaletteRemapping(
        imageData,
        sharedPaletteData,
        tx * 8,
        ty * 8,
        paletteWithSharedBg,
        sharedPalette,
      );

      tileIndex++;
    }
  }

  // Draw results
  const convertedCtx = convertedCanvas.getContext("2d");
  convertedCtx.putImageData(convertedData, 0, 0);

  const sharedPaletteCtx = sharedPaletteCanvas.getContext("2d");
  sharedPaletteCtx.putImageData(sharedPaletteData, 0, 0);

  // Initialize NES palette display
  initializeNESPalette();

  // Display palettes and stats
  displayPalettes();
  displayColorStats();

  // Show results
  document.getElementById("results").style.display = "block";
}

function isTileEmpty(imageData, x, y) {
  // Check if a tile is fully transparent or fully black
  for (let py = 0; py < 8; py++) {
    for (let px = 0; px < 8; px++) {
      const idx = ((y + py) * imageData.width + (x + px)) * 4;
      const r = imageData.data[idx];
      const g = imageData.data[idx + 1];
      const b = imageData.data[idx + 2];
      const a = imageData.data[idx + 3];

      // If we find any non-black or non-transparent pixel, tile is not empty
      if (a > 0 && (r > 0 || g > 0 || b > 0)) {
        return false;
      }
    }
  }
  return true;
}

function extractTile(imageData, x, y) {
  const tile = [];
  for (let py = 0; py < 8; py++) {
    for (let px = 0; px < 8; px++) {
      const idx = ((y + py) * imageData.width + (x + px)) * 4;
      tile.push([
        imageData.data[idx],
        imageData.data[idx + 1],
        imageData.data[idx + 2],
      ]);
    }
  }
  return tile;
}

function generateSharedPalette(colorUsage) {
  // Sort colors by usage
  const sorted = Object.entries(colorUsage)
    .sort((a, b) => b[1] - a[1])
    .map(([color]) => color.split(",").map(Number));

  // The most common color becomes the background (index 0)
  const backgroundColor = sorted.length > 0 ? sorted[0] : [0, 0, 0];

  // Take the next 3 most common colors for the palette
  const paletteColors = sorted.slice(1, 4);

  // Ensure we have exactly 3 palette colors
  while (paletteColors.length < 3) {
    paletteColors.push([0, 0, 0]);
  }

  // Return with background color at index 0
  return [backgroundColor, ...paletteColors];
}

function generateTilePalette(tile) {
  // Convert all colors to NES colors first
  const nesColors = tile.map((color) => findClosestNESColor(color));

  // Count color usage in this tile
  const colorCount = {};
  nesColors.forEach((color) => {
    const key = color.join(",");
    colorCount[key] = (colorCount[key] || 0) + 1;
  });

  // Sort by usage
  const sorted = Object.entries(colorCount)
    .sort((a, b) => b[1] - a[1])
    .map(([color]) => color.split(",").map(Number));

  // For NES, we need the most common color as background (index 0)
  // and up to 3 additional colors
  const backgroundColor = sorted.length > 0 ? sorted[0] : [0, 0, 0];
  const paletteColors = sorted.slice(1, 4);

  // Ensure we have exactly 3 palette colors
  while (paletteColors.length < 3) {
    paletteColors.push([0, 0, 0]); // $0F - safe black
  }

  // Return with background color at index 0
  return [backgroundColor, ...paletteColors];
}

function generateTilePaletteWithBackground(tile, backgroundCol) {
  // Convert all colors to NES colors first
  const nesColors = tile.map((color) => findClosestNESColor(color));

  // Count color usage in this tile
  const colorCount = {};
  nesColors.forEach((color) => {
    const key = color.join(",");
    colorCount[key] = (colorCount[key] || 0) + 1;
  });

  // Remove the background color from consideration if it exists
  const bgKey = backgroundCol.join(",");
  delete colorCount[bgKey];

  // Sort remaining colors by usage and take top 3
  const sorted = Object.entries(colorCount)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([color]) => color.split(",").map(Number));

  // Ensure we have exactly 3 palette colors
  while (sorted.length < 3) {
    sorted.push([0, 0, 0]); // $0F - safe black
  }

  // Return with shared background color at index 0
  return [backgroundCol, ...sorted];
}

function findClosestNESColor(color) {
  let minDist = Infinity;
  let closest = NES_PALETTE[0];

  // Special handling for very dark colors
  const brightness = (color[0] + color[1] + color[2]) / 3;
  if (brightness < 20) {
    // Use safe black $0F instead of problematic $0D
    return [0, 0, 0]; // This is index 0x0F in our palette
  }

  // Convert RGB to Lab color space for better perceptual matching
  const lab1 = rgbToLab(color[0], color[1], color[2]);

  for (let i = 0; i < NES_PALETTE.length; i++) {
    const nesColor = NES_PALETTE[i];

    // Skip color $0D (the "blacker than black" that causes TV problems)
    // Also skip duplicate blacks (0x0E, 0x1D-0x1F, 0x2E-0x2F, 0x3E-0x3F)
    if (
      i === 0x0d ||
      i === 0x0e ||
      (i >= 0x1d && i <= 0x1f) ||
      (i >= 0x2e && i <= 0x2f) ||
      (i >= 0x3e && i <= 0x3f)
    ) {
      continue;
    }

    const lab2 = rgbToLab(nesColor[0], nesColor[1], nesColor[2]);

    // Calculate Delta E (CIE76) - perceptual color difference
    const deltaE = Math.sqrt(
      Math.pow(lab1.L - lab2.L, 2) +
        Math.pow(lab1.a - lab2.a, 2) +
        Math.pow(lab1.b - lab2.b, 2),
    );

    // For very light colors, give extra weight to lightness differences
    let adjustedDist = deltaE;
    if (lab1.L > 85) {
      // Light colors
      const lightnessDiff = Math.abs(lab1.L - lab2.L);
      adjustedDist = deltaE + lightnessDiff * 0.5;
    }

    if (adjustedDist < minDist) {
      minDist = adjustedDist;
      closest = nesColor;
    }
  }

  return closest;
}

function rgbToLab(r, g, b) {
  // First convert to XYZ color space
  r = r / 255;
  g = g / 255;
  b = b / 255;

  // Apply gamma correction
  r = r > 0.04045 ? Math.pow((r + 0.055) / 1.055, 2.4) : r / 12.92;
  g = g > 0.04045 ? Math.pow((g + 0.055) / 1.055, 2.4) : g / 12.92;
  b = b > 0.04045 ? Math.pow((b + 0.055) / 1.055, 2.4) : b / 12.92;

  // Convert to XYZ using sRGB matrix
  let x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375;
  let y = r * 0.2126729 + g * 0.7151522 + b * 0.072175;
  let z = r * 0.0193339 + g * 0.119192 + b * 0.9503041;

  // Normalize for D65 illuminant
  x = x / 0.95047;
  y = y / 1.0;
  z = z / 1.08883;

  // Convert to Lab
  const fx = x > 0.008856 ? Math.pow(x, 1 / 3) : 7.787 * x + 16 / 116;
  const fy = y > 0.008856 ? Math.pow(y, 1 / 3) : 7.787 * y + 16 / 116;
  const fz = z > 0.008856 ? Math.pow(z, 1 / 3) : 7.787 * z + 16 / 116;

  const L = 116 * fy - 16;
  const labA = 500 * (fx - fy);
  const labB = 200 * (fy - fz);

  return { L, a: labA, b: labB };
}

function rgbToHsl(r, g, b) {
  r /= 255;
  g /= 255;
  b /= 255;

  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h,
    s,
    l = (max + min) / 2;

  if (max === min) {
    h = s = 0; // achromatic
  } else {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

    switch (max) {
      case r:
        h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
        break;
      case g:
        h = ((b - r) / d + 2) / 6;
        break;
      case b:
        h = ((r - g) / d + 4) / 6;
        break;
    }
  }

  return [h * 360, s * 100, l * 100];
}

function findClosestPaletteColor(color, palette) {
  let minDist = Infinity;
  let closest = palette[0];

  for (const pColor of palette) {
    const dist = Math.sqrt(
      Math.pow(color[0] - pColor[0], 2) +
        Math.pow(color[1] - pColor[1], 2) +
        Math.pow(color[2] - pColor[2], 2),
    );

    if (dist < minDist) {
      minDist = dist;
      closest = pColor;
    }
  }

  return closest;
}

function applyIndividualPaletteToTile(sourceData, targetData, x, y, palette) {
  // This is the original function for individual palette conversion
  for (let py = 0; py < 8; py++) {
    for (let px = 0; px < 8; px++) {
      const idx = ((y + py) * sourceData.width + (x + px)) * 4;
      const color = [
        sourceData.data[idx],
        sourceData.data[idx + 1],
        sourceData.data[idx + 2],
      ];

      // First convert to NES color
      const nesColor = findClosestNESColor(color);
      // Then find closest color in the palette
      const paletteColor = findClosestPaletteColor(nesColor, palette);

      targetData.data[idx] = paletteColor[0];
      targetData.data[idx + 1] = paletteColor[1];
      targetData.data[idx + 2] = paletteColor[2];
      targetData.data[idx + 3] = 255;
    }
  }
}

function applySharedPaletteRemapping(
  sourceData,
  targetData,
  x,
  y,
  tilePalette,
  sharedPalette,
) {
  // This function remaps colors by palette position
  for (let py = 0; py < 8; py++) {
    for (let px = 0; px < 8; px++) {
      const idx = ((y + py) * sourceData.width + (x + px)) * 4;
      const color = [
        sourceData.data[idx],
        sourceData.data[idx + 1],
        sourceData.data[idx + 2],
      ];

      // First convert to NES color
      const nesColor = findClosestNESColor(color);

      // Find which position this color is in the tile's individual palette
      let paletteIndex = -1;
      for (let i = 0; i < tilePalette.length; i++) {
        if (
          tilePalette[i][0] === nesColor[0] &&
          tilePalette[i][1] === nesColor[1] &&
          tilePalette[i][2] === nesColor[2]
        ) {
          paletteIndex = i;
          break;
        }
      }

      // If color not found in tile palette, find closest
      if (paletteIndex === -1) {
        let minDist = Infinity;
        for (let i = 0; i < tilePalette.length; i++) {
          const dist = Math.sqrt(
            Math.pow(nesColor[0] - tilePalette[i][0], 2) +
              Math.pow(nesColor[1] - tilePalette[i][1], 2) +
              Math.pow(nesColor[2] - tilePalette[i][2], 2),
          );
          if (dist < minDist) {
            minDist = dist;
            paletteIndex = i;
          }
        }
      }

      // Use the color from the shared palette at the same index position
      // This ensures color 0 in tile palette maps to color 0 in shared palette, etc.
      const sharedColor = sharedPalette[paletteIndex];

      targetData.data[idx] = sharedColor[0];
      targetData.data[idx + 1] = sharedColor[1];
      targetData.data[idx + 2] = sharedColor[2];
      targetData.data[idx + 3] = 255;
    }
  }
}

function displayPalettes() {
  const container = document.getElementById("palettesContainer");
  container.innerHTML = "";

  // Show shared palette first
  const sharedDiv = document.createElement("div");
  sharedDiv.className = "palette-item";
  sharedDiv.style.background = "#e3f2fd";
  sharedDiv.innerHTML = `
    <div><strong>Shared Palette (Most Used)</strong></div>
    <div class="palette-colors">
      ${sharedPalette
        .map((color, index) => {
          const colorIndex = getNESColorIndex(color);
          const name = getColorName(color);
          const label = index === 0 ? "BG" : colorIndex;
          return `<div class="color-box" style="background: rgb(${color.join(",")})" title="${name} (${index === 0 ? "Background" : "Color " + index})">${label}</div>`;
        })
        .join("")}
    </div>
  `;
  container.appendChild(sharedDiv);

  // Show background color info
  const bgDiv = document.createElement("div");
  bgDiv.className = "palette-item";
  bgDiv.style.background = "#fff3cd";
  const bgColorIndex = getNESColorIndex(globalBackgroundColor);
  const bgName = getColorName(globalBackgroundColor);
  bgDiv.innerHTML = `
    <div><strong>Global Background Color</strong></div>
    <div class="palette-colors">
      <div class="color-box" style="background: rgb(${globalBackgroundColor.join(",")})" title="${bgName}">${bgColorIndex}</div>
      <div style="margin-left: 10px; align-self: center;">Shared across all palettes (index 0)</div>
    </div>
  `;
  container.appendChild(bgDiv);

  // Get the background palletes
  const ranking = getTopPalettes(tilePalettes, 6);
  ranking.forEach((element, index) => {
    const div = document.createElement("div");
    div.className = "palette-item";
    div.innerHTML = `
      <div>Number ${index + 1} most used palette</div>
      <div class="palette-colors">
        ${element.palette
          .map((color, index) => {
            const colorIndex = getNESColorIndex(color);
            const name = getColorName(color);
            const label = index === 0 ? "BG" : colorIndex;
            return `<div class="color-box" style="background: rgb(${color.join(",")}); ${index === 0 ? "border: 2px solid #ff6b6b;" : ""}" title="${name} (${index === 0 ? "Shared BG" : "Color " + index})">${label}</div>`;
          })
          .join("")}
      </div>
    `;
    container.appendChild(div);
  });

  // Show individual tile palettes with shared background
  tilePalettes.forEach((tile) => {
    const div = document.createElement("div");
    div.className = "palette-item";
    div.innerHTML = `
      <div>Tile ${tile.index} (${tile.x}, ${tile.y})</div>
      <div style="font-size: 0.9em; color: #666; margin: 5px 0;">Individual palette:</div>
      <div class="palette-colors">
        ${tile.palette
          .map((color, index) => {
            const colorIndex = getNESColorIndex(color);
            const name = getColorName(color);
            return `<div class="color-box" style="background: rgb(${color.join(",")})" title="${name}">${colorIndex}</div>`;
          })
          .join("")}
      </div>
      <div style="font-size: 0.9em; color: #666; margin: 5px 0;">With shared BG:</div>
      <div class="palette-colors">
        ${tile.paletteWithSharedBg
          .map((color, index) => {
            const colorIndex = getNESColorIndex(color);
            const name = getColorName(color);
            const label = index === 0 ? "BG" : colorIndex;
            return `<div class="color-box" style="background: rgb(${color.join(",")}); ${index === 0 ? "border: 2px solid #ff6b6b;" : ""}" title="${name} (${index === 0 ? "Shared BG" : "Color " + index})">${label}</div>`;
          })
          .join("")}
      </div>
    `;
    container.appendChild(div);
  });
}

function getPaletteRanking(tilePalettes) {
  // Count occurrences of each paletteWithSharedBg
  const paletteCount = {};

  tilePalettes.forEach((tile) => {
    const palette = tile.paletteWithSharedBg;
    // Convert palette to string for comparison (handles arrays/objects)
    const paletteKey = JSON.stringify(palette);
    paletteCount[paletteKey] = (paletteCount[paletteKey] || 0) + 1;
  });

  // Convert to array of objects and sort by count (descending)
  const ranking = Object.entries(paletteCount)
    .map(([paletteKey, count]) => ({
      palette: JSON.parse(paletteKey),
      count: count,
      percentage: ((count / tilePalettes.length) * 100).toFixed(2),
    }))
    .sort((a, b) => b.count - a.count);

  return ranking;
}

// Alternative version if you want just the top N results
function getTopPalettes(tilePalettes, topN = 10) {
  const ranking = getPaletteRanking(tilePalettes);
  return ranking.slice(0, topN);
}

function displayColorStats() {
  const statsDiv = document.getElementById("colorStats");
  const histogramDiv = document.getElementById("colorHistogram");

  // Sort colors by usage
  const sortedColors = Object.entries(globalColorUsage)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 16); // Show top 16 colors

  // Display stats
  const totalPixels = Object.values(globalColorUsage).reduce(
    (a, b) => a + b,
    0,
  );
  statsDiv.innerHTML = `
    <p>Total pixels: ${totalPixels}</p>
    <p>Unique NES colors used: ${Object.keys(globalColorUsage).length}</p>
  `;

  // Display histogram
  histogramDiv.innerHTML = sortedColors
    .map(([color, count]) => {
      const rgb = color.split(",").map(Number);
      const percentage = ((count / totalPixels) * 100).toFixed(1);
      const colorIndex = getNESColorIndex(rgb);
      const name = getColorName(rgb);
      return `
        <div class="histogram-color">
          <div class="histogram-box" style="background: rgb(${color})" title="${name}"></div>
          <div>${colorIndex}</div>
          <div>${percentage}%</div>
        </div>
      `;
    })
    .join("");
}

function downloadCanvas(canvasId, filename) {
  const canvas = document.getElementById(canvasId);
  const link = document.createElement("a");
  link.download = filename;
  link.href = canvas.toDataURL();
  link.click();
}

// CHR Conversion Functions
/**
 * Converts the shared palette image data to NES CHR format
 * @param {ImageData} imageData - The shared palette image data from canvas
 * @param {Array} sharedPalette - The 4-color shared palette array
 * @returns {Uint8Array} - CHR data ready to be saved as .chr file
 */
function convertToCHR(imageData, sharedPalette) {
  const width = imageData.width;
  const height = imageData.height;
  const tilesX = width / 8;
  const tilesY = height / 8;
  const totalTiles = tilesX * tilesY;

  // CHR format: each tile is 16 bytes (8 bytes for low plane, 8 bytes for high plane)
  const chrData = new Uint8Array(totalTiles * 16);
  let chrIndex = 0;

  // Process each 8x8 tile
  for (let ty = 0; ty < tilesY; ty++) {
    for (let tx = 0; tx < tilesX; tx++) {
      // Get tile data
      const tile = extractTileData(imageData, tx * 8, ty * 8);

      // Convert tile to CHR format
      const chrTile = convertTileToCHR(tile, sharedPalette);

      // Copy CHR tile data
      for (let i = 0; i < 16; i++) {
        chrData[chrIndex++] = chrTile[i];
      }
    }
  }

  return chrData;
}

/**
 * Extract pixel data for a single 8x8 tile
 * @param {ImageData} imageData - Source image data
 * @param {number} x - Tile X position
 * @param {number} y - Tile Y position
 * @returns {Array} - 8x8 array of RGB colors
 */
function extractTileData(imageData, x, y) {
  const tile = [];
  for (let row = 0; row < 8; row++) {
    const rowData = [];
    for (let col = 0; col < 8; col++) {
      const idx = ((y + row) * imageData.width + (x + col)) * 4;
      rowData.push([
        imageData.data[idx],
        imageData.data[idx + 1],
        imageData.data[idx + 2],
      ]);
    }
    tile.push(rowData);
  }
  return tile;
}

/**
 * Convert a single tile to CHR format
 * @param {Array} tile - 8x8 array of RGB colors
 * @param {Array} palette - 4-color palette array
 * @returns {Uint8Array} - 16 bytes of CHR data
 */
function convertTileToCHR(tile, palette) {
  const chrTile = new Uint8Array(16);

  // Create color to palette index mapping
  const colorToIndex = new Map();
  palette.forEach((color, index) => {
    colorToIndex.set(color.join(","), index);
  });

  // Process each row of the tile
  for (let row = 0; row < 8; row++) {
    let lowByte = 0;
    let highByte = 0;

    // Process each pixel in the row
    for (let col = 0; col < 8; col++) {
      const pixelColor = tile[row][col];

      // Find closest palette color
      let paletteIndex = 0;
      let minDist = Infinity;

      for (let i = 0; i < palette.length; i++) {
        const pColor = palette[i];
        const dist = colorDistance(pixelColor, pColor);
        if (dist < minDist) {
          minDist = dist;
          paletteIndex = i;
        }
      }

      // Set the appropriate bits
      if (paletteIndex & 1) {
        lowByte |= 1 << (7 - col);
      }
      if (paletteIndex & 2) {
        highByte |= 1 << (7 - col);
      }
    }

    // Store the bytes (low plane first, then high plane)
    chrTile[row] = lowByte;
    chrTile[row + 8] = highByte;
  }

  return chrTile;
}

/**
 * Calculate distance between two RGB colors
 * @param {Array} color1 - First RGB color [r, g, b]
 * @param {Array} color2 - Second RGB color [r, g, b]
 * @returns {number} - Euclidean distance
 */
function colorDistance(color1, color2) {
  return Math.sqrt(
    Math.pow(color1[0] - color2[0], 2) +
      Math.pow(color1[1] - color2[1], 2) +
      Math.pow(color1[2] - color2[2], 2),
  );
}

/**
 * Download CHR file
 * @param {Uint8Array} chrData - CHR data to download
 * @param {string} filename - Name for the downloaded file
 */
function downloadCHR(chrData, filename = "tileset.chr") {
  const blob = new Blob([chrData], { type: "application/octet-stream" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

/**
 * Main function to convert shared palette canvas to CHR and download
 * Call this when user clicks a "Download CHR" button
 */
function convertSharedPaletteToCHR() {
  const canvas = document.getElementById("sharedPaletteCanvas");
  const ctx = canvas.getContext("2d");
  const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);

  // Make sure sharedPalette is available
  if (!sharedPalette || sharedPalette.length !== 4) {
    alert("Error: Shared palette not found or invalid");
    return;
  }

  // Convert to CHR
  const chrData = convertToCHR(imageData, sharedPalette);

  // Download the file
  downloadCHR(chrData, "nes_tiles.chr");
}

// Initialize NES palette on page load
window.addEventListener("DOMContentLoaded", initializeNESPalette);
