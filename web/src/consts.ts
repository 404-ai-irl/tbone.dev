// Place any global data in this file.
// You can import this data from anywhere in your site by using the `import` keyword.

export const SITE_TITLE = 'tbone.dev';
export const SITE_DESCRIPTION = 'Chronicles of an ancient order—where code, consciousness, and contemplation converge. Explorations in systems design, AI philosophy, and the craft of precise machinery.';

// TheRoyalOrphan tag color palette — single source of truth
// ROYAL: Bronze/Gold  |  DIVINE: Cardinal, Emerald, Sapphire, Crimson
export const TAG_COLORS: Record<string, string> = {
	astro:      '#DC143C', // Crimson  — bold & distinctive
	javascript: '#D4AF37', // Gold     — classic JS yellow mapped to Gold
	typescript: '#0F52BA', // Sapphire — intelligent & typed
	networking: '#50C878', // Emerald  — flow & connectivity
	nix:        '#B8956A', // Bronze   — structural, foundational
	ai:         '#C41E3A', // Cardinal — energy & vitality
	devops:     '#708090', // Slate    — infrastructure, neutral
	tutorial:   '#50C878', // Emerald  — growth & learning
};
