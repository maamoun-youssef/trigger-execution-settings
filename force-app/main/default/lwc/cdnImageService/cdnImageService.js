export const cdnImages = [
    { name: 'ADP1_small',category: 'Apps', url: 'https://cdn.designfast.io/image/2025-11-01/9fbc65cd-0c70-48c6-a861-9dcec1dedc66.png' },
    { name: 'ADP1_medium',category: 'Apps', url: 'https://cdn.designfast.io/image/2025-11-01/9ae559d5-4547-4504-9099-7131c36c670c.png' },
    { name: 'ADP1_large',category: 'Apps', url: 'https://cdn.designfast.io/image/2025-11-01/287d6d09-ef3c-4fdc-97ad-b08b724032e3.png' },
];

// export const imageCache = {};

// export function getImageByName(imageName) {
//     if (imageCache[imageName]) return imageCache[imageName];
//     const cleanName = imageName.replace(/\.[^/.]+$/, '');
//     const cdnMatch = cdnImages.find(img => img.name === cleanName);
//     if (cdnMatch) {
//         imageCache[imageName] = cdnMatch.url;
//         return cdnMatch.url;
//     }
//     return null;
// }

// export function getImagesByBaseName(baseName) {
//     return cdnImages.filter(img => img.name.startsWith(baseName));
// }