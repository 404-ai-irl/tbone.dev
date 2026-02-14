/**
 * Calculate reading time for a given text
 * Average reading speed: 200 words per minute
 */
export function getReadingTime(content: string): number {
	const wordsPerMinute = 200;
	const words = content.trim().split(/\s+/).length;
	return Math.ceil(words / wordsPerMinute);
}

/**
 * Format a date to a readable string
 */
export function formatDate(date: Date): string {
	return new Intl.DateTimeFormat('en-US', {
		year: 'numeric',
		month: 'short',
		day: 'numeric',
	}).format(date);
}

/**
 * Get unique tags from all posts
 */
export function getUniqueTags(posts: { data: { tags?: string[] } }[]): string[] {
	const tags = new Set<string>();
	posts.forEach((post) => {
		post.data.tags?.forEach((tag) => tags.add(tag));
	});
	return Array.from(tags).sort();
}

/**
 * Group posts by tag
 */
export function getPostsByTag(
	posts: { id: string; data: { tags?: string[] } }[]
): Map<string, { id: string; data: { tags?: string[] } }[]> {
	const map = new Map<string, { id: string; data: { tags?: string[] } }[]>();
	
	posts.forEach((post) => {
		post.data.tags?.forEach((tag) => {
			if (!map.has(tag)) {
				map.set(tag, []);
			}
			map.get(tag)!.push(post);
		});
	});
	
	return map;
}

/**
 * Get related posts based on shared tags
 */
export function getRelatedPosts(
	currentPost: { id: string; data: { tags?: string[] } },
	allPosts: { id: string; data: { tags?: string[] }; body: string }[],
	limit = 3
) {
	const currentTags = new Set(currentPost.data.tags || []);
	
	return allPosts
		.filter((post) => post.id !== currentPost.id)
		.map((post) => ({
			...post,
			score: post.data.tags?.filter((tag) => currentTags.has(tag)).length || 0,
		}))
		.filter((post) => post.score > 0)
		.sort((a, b) => b.score - a.score)
		.slice(0, limit);
}
