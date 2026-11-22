
package com.attendance;

import java.time.DayOfWeek;
import java.time.Duration;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

@WebListener
public class AttendanceAlertSchedulerListener
        implements ServletContextListener {

    private static final ZoneId TIME_ZONE =
            ZoneId.of("Asia/Kolkata");

    private static final DayOfWeek SCHEDULED_DAY =
            DayOfWeek.SUNDAY;

    private static final LocalTime SCHEDULED_TIME =
            LocalTime.of(18, 0);

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent event) {

        String schedulerEnabled =
                System.getenv("ATTENDANCE_LOCAL_SCHEDULER_ENABLED");

        if ("false".equalsIgnoreCase(schedulerEnabled)) {
            event.getServletContext().log(
                    "Local attendance scheduler disabled by environment configuration."
            );
            return;
        }

        scheduler = Executors.newSingleThreadScheduledExecutor(task -> {
            Thread thread = new Thread(
                    task,
                    "AttendancePro-Weekly-Alert-Scheduler"
            );

            thread.setDaemon(true);
            return thread;
        });

        long initialDelay = calculateInitialDelay();

        ZonedDateTime nextRun = ZonedDateTime.now(TIME_ZONE)
                .plusNanos(
                        TimeUnit.MILLISECONDS.toNanos(initialDelay)
                );

        event.getServletContext().log(
                "AttendancePro Weekly Alert Scheduler initialized. "
                + "Next execution: " + nextRun
        );

        scheduler.schedule(
                this::executeWeeklyAlerts,
                initialDelay,
                TimeUnit.MILLISECONDS
        );
    }

    private long calculateInitialDelay() {

        ZonedDateTime now = ZonedDateTime.now(TIME_ZONE);

        ZonedDateTime nextRun = now
                .with(DayOfWeek.SUNDAY)
                .with(SCHEDULED_TIME);

        if (!nextRun.isAfter(now)) {
            nextRun = nextRun.plusWeeks(1);
        }

        return Duration.between(now, nextRun).toMillis();
    }

    private void executeWeeklyAlerts() {

        try {

            ZonedDateTime executionTime =
                    ZonedDateTime.now(TIME_ZONE);

            System.out.println(
                    "[AttendancePro Weekly Scheduler] Started: "
                    + executionTime
            );

            int sentCount =
                    AttendanceAlertService.sendLowAttendanceAlerts();

            System.out.println(
                    "[AttendancePro Weekly Scheduler] Completed. "
                    + "Emails sent: " + sentCount
            );

        } catch (Exception e) {

            System.err.println(
                    "[AttendancePro Weekly Scheduler] Failed: "
                    + e.getMessage()
            );

            e.printStackTrace();

        } finally {

            scheduleNextSunday();
        }
    }

    private void scheduleNextSunday() {

        if (scheduler == null || scheduler.isShutdown()) {
            return;
        }

        long nextDelay = calculateInitialDelay();

        scheduler.schedule(
                this::executeWeeklyAlerts,
                nextDelay,
                TimeUnit.MILLISECONDS
        );
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {

        if (scheduler != null) {

            scheduler.shutdown();

            try {

                if (!scheduler.awaitTermination(30, TimeUnit.SECONDS)) {
                    scheduler.shutdownNow();
                }

            } catch (InterruptedException e) {

                scheduler.shutdownNow();
                Thread.currentThread().interrupt();
            }
        }

        event.getServletContext().log(
                "AttendancePro Weekly Alert Scheduler stopped."
        );
    }
}
