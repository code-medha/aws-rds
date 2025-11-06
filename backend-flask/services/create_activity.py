import uuid
import os
from datetime import datetime, timedelta, timezone
from psycopg_pool import ConnectionPool

connection_url=os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)

class CreateActivity:
  def run(message, user_handle, ttl):
    model = {
      'errors': None,
      'data': None
    }

    now = datetime.now(timezone.utc).astimezone()

    if (ttl == '30-days'):
      ttl_offset = timedelta(days=30) 
    elif (ttl == '7-days'):
      ttl_offset = timedelta(days=7) 
    elif (ttl == '3-days'):
      ttl_offset = timedelta(days=3) 
    elif (ttl == '1-day'):
      ttl_offset = timedelta(days=1) 
    elif (ttl == '12-hours'):
      ttl_offset = timedelta(hours=12) 
    elif (ttl == '3-hours'):
      ttl_offset = timedelta(hours=3) 
    elif (ttl == '1-hour'):
      ttl_offset = timedelta(hours=1) 
    else:
      model['errors'] = ['ttl_blank']

    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['user_handle_blank']

    if message == None or len(message) < 1:
      model['errors'] = ['message_blank'] 
    elif len(message) > 280:
      model['errors'] = ['message_exceed_max_chars'] 

    if model['errors']:
      model['data'] = {
        'handle':  user_handle,
        'message': message
      }   
    else:
      expires_at = (now + ttl_offset)

     
      with pool.connection() as conn:
          with conn.cursor() as cur:
              cur.execute(
                  "SELECT uuid, display_name FROM public.users WHERE handle = %s LIMIT 1",
                  [user_handle]
              )
              user_row = cur.fetchone()
              if user_row is None:
                  model['errors'] = ['user_handle_not_found']
                  model['data'] = { 'handle': user_handle, 'message': message }
                  return model

              user_uuid, display_name = user_row[0], user_row[1]

              insert_sql = """
                  INSERT INTO public.activities (user_uuid, message, expires_at)
                  VALUES (%s, %s, %s)
                  RETURNING uuid, message, created_at, expires_at
              """
              cur.execute(insert_sql, [user_uuid, message, expires_at])
              result = cur.fetchone()
              conn.commit()

      model['data'] = {
          'uuid': result[0],
          'display_name': display_name,
          'handle': user_handle,
          'message': result[1],
          'created_at': result[2].isoformat(),
          'expires_at': result[3].isoformat()
      }
      return model
