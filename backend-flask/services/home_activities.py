from datetime import datetime, timedelta, timezone
from psycopg_pool import ConnectionPool
from opentelemetry import trace
import os
import time
import random

tracer = trace.get_tracer("home.activity")

connection_url=os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)

class HomeActivities:
  def run(cognito_user_id=None):
    with tracer.start_as_current_span("mock-data-db") as span:
      # Simulate slow latency if env var is set
      if os.getenv("SIMULATE_HOME_LATENCY") == "1":
        delay = round(random.uniform(1, 3), 2)
        span.set_attribute("mock.latency", delay)
        print(f"[HomeActivities] Simulating latency: {delay}s")
        time.sleep(delay)

      # Simulate error via env variable (useful in tests)
      if os.getenv("SIMULATE_HOME_ERROR") == "1":
        span.set_attribute("mock.error", True)
        raise Exception("Simulated error from HomeActivities")
  
    sql = """
    SELECT COALESCE(
      array_to_json(array_agg(row_to_json(row_results))),
      '[]'::json
    ) as activities
    FROM (
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    ) row_results
    """
    
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        activities = cur.fetchone() 
    
    print(activities[0])
    return activities[0] if activities and activities[0] is not None else []

