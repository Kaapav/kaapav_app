// get-logo.js
async function getLogoForEmbed() {
  try {
    console.log('🔄 Fetching logo from Cloudflare R2...\n');
    
    const res = await fetch('https://pub-e8a17aa027ff420f83623e808512141f.r2.dev/kaapav_logo.jpg');
    
    if (!res.ok) {
      console.error('❌ Fetch failed:', res.status, res.statusText);
      return;
    }
    
    const bytes = new Uint8Array(await res.arrayBuffer());
    console.log('✅ Logo fetched successfully! Size:', bytes.length, 'bytes\n');
    
    // Get dimensions from JPEG
    let width = 0, height = 0;
    for (let i = 0; i < bytes.length - 9; i++) {
      if (bytes[i] === 0xFF) {
        const marker = bytes[i + 1];
        if ((marker >= 0xC0 && marker <= 0xC3) || 
            (marker >= 0xC5 && marker <= 0xC7) || 
            (marker >= 0xC9 && marker <= 0xCB) || 
            (marker >= 0xCD && marker <= 0xCF)) {
          height = (bytes[i + 5] << 8) | bytes[i + 6];
          width = (bytes[i + 7] << 8) | bytes[i + 8];
          break;
        }
      }
    }
    
    console.log('📐 Logo dimensions:', width, 'x', height, '\n');
    
    // Convert to hex for PDF
    let hex = '';
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0');
    }
    
    console.log('='.repeat(70));
    console.log('✅ SUCCESS! Copy the code below into your worker:');
    console.log('='.repeat(70));
    console.log('\n// ═══════════════════ EMBEDDED LOGO DATA ═══════════════════');
    console.log('const EMBEDDED_LOGO = {');
    console.log(`  type: 'jpeg',`);
    console.log(`  width: ${width},`);
    console.log(`  height: ${height},`);
    console.log(`  hex: '${hex.toUpperCase()}>'`);
    console.log('};\n');
    console.log('='.repeat(70));
    console.log('📋 Now add this to your worker code and use EMBEDDED_LOGO');
    console.log('='.repeat(70));
    
  } catch (e) {
    console.error('❌ Error:', e.message);
  }
}

// Run it
getLogoForEmbed();