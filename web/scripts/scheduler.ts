#!/usr/bin/env bun
/**
 * Bun-based job scheduler
 * 
 * Run with: bun run schedule
 * Or directly: bun run scripts/scheduler.ts
 */

import { Cron } from "croner";

// Configure your scheduled jobs here
interface JobConfig {
  name: string;
  schedule: string;  // Cron expression
  timezone?: string;
  task: () => void | Promise<void>;
}

const jobs: JobConfig[] = [
  {
    name: "Daily Site Build",
    schedule: "0 8 * * *",  // 8:00 AM daily
    timezone: "America/Chicago",
    task: async () => {
      console.log(`[${new Date().toISOString()}] Running daily build...`);
      const proc = Bun.spawn(["bun", "run", "build"], {
        cwd: process.cwd(),
        stdout: "inherit",
        stderr: "inherit",
      });
      await proc.exited;
      console.log(`[${new Date().toISOString()}] Build complete`);
    },
  },
  {
    name: "Health Check",
    schedule: "*/5 * * * *",  // Every 5 minutes (for demo - remove or adjust)
    task: () => {
      console.log(`[${new Date().toISOString()}] Scheduler heartbeat`);
    },
  },
];

// Initialize all jobs
console.log("🕐 Starting scheduler...\n");

for (const job of jobs) {
  const cron = new Cron(job.schedule, {
    timezone: job.timezone,
    protect: true,  // Prevent overlapping runs
  }, async () => {
    try {
      await job.task();
    } catch (error) {
      console.error(`[${job.name}] Error:`, error);
    }
  });

  console.log(`  ✓ ${job.name}`);
  console.log(`    Schedule: ${job.schedule} ${job.timezone ? `(${job.timezone})` : ""}`);
  console.log(`    Next run: ${cron.nextRun()?.toLocaleString() || "N/A"}`);
  console.log();
}

console.log("Press Ctrl+C to stop\n");

// Keep process alive
setInterval(() => {}, 1000);
