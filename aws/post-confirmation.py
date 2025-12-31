import psycopg2
import os
import json


def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes:', user)

    user_display_name  = user.get('name')
    user_email         = user.get('email')
    user_handle        = user.get('preferred_username')
    user_cognito_id    = user.get('sub')

    conn = None 

    try:
        sql = """
        INSERT INTO public.users (
          display_name, email, handle, cognito_user_id
        ) VALUES (%s, %s, %s, %s)
        """       

        conn = psycopg2.connect(os.getenv("CONNECTION_URL"))
        cur = conn.cursor()
        cur.execute(sql, (user_display_name, user_email, user_handle, user_cognito_id))
        conn.commit()
        cur.close()
        print('Insert committed.')
    except (Exception, psycopg2.DatabaseError) as error:
        print('DB error:', error)

    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event        


