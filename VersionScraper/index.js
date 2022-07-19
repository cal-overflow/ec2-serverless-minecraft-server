import fetch from 'node-fetch';
import fs from 'fs';

const targetServerVersion = process.env.SERVER_VERSION || 'latest';

fetch('https://launchermeta.mojang.com/mc/game/version_manifest.json')
.then(async (response) => {
  const data = await response.json();

  let targetReleaseInfo;

  
  if (targetServerVersion === 'latest') {
    fs.writeFileSync('./targetVersion.txt', data.latest.release);
    console.log('Target release version successfully written to targetVersion.txt');

    console.log(`Searching for latest release (version ${data.latest.release}) information`);
    targetReleaseInfo = data.versions.find(({ id }) => id === data.latest.release);
  }
  else {
    fs.writeFileSync('./targetVersion.txt', targetServerVersion);
    console.log('Target release version successfully written to targetVersion.txt');

    console.log(`Searching for release ${targetServerVersion} information`);
    targetReleaseInfo = data.versions.find(({ id }) => id === targetServerVersion);
  }

  if (!targetReleaseInfo) throw new Error(`Unable to find information for release "${targetServerVersion}"`);

  const targetReleaseResponse = await fetch(targetReleaseInfo.url);
  const targetReleaseData = await targetReleaseResponse.json();
  
  fs.writeFileSync('./url.txt', targetReleaseData.downloads.server.url);
  console.log('URL successfully written to url.txt');
});
