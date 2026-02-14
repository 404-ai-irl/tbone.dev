import { defineCollection, z } from 'astro:content';
import { glob, file } from 'astro/loaders';

// Blog collection with enhanced schema
const blog = defineCollection({
	loader: glob({ base: './src/content/blog', pattern: '**/*.{md,mdx}' }),
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			description: z.string(),
			pubDate: z.coerce.date(),
			updatedDate: z.coerce.date().optional(),
			heroImage: image().optional(),
			// New fields
			tags: z.array(z.string()).default([]),
			author: z.string().default('tbone'),
			draft: z.boolean().default(false),
			featured: z.boolean().default(false),
		}),
});

// Authors collection
const authors = defineCollection({
	loader: glob({ base: './src/content/authors', pattern: '*.json' }),
	schema: z.object({
		name: z.string(),
		bio: z.string(),
		avatar: z.string().optional(),
		website: z.string().optional(),
		twitter: z.string().optional(),
		github: z.string().optional(),
	}),
});

// Tags metadata - use glob instead of file for better control
const tags = defineCollection({
	loader: glob({ base: './src/content/tags', pattern: '*.json' }),
	schema: z.object({
		description: z.string(),
		color: z.string().optional(),
	}),
});

export const collections = { blog, authors, tags };
