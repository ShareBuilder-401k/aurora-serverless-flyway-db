CREATE OR REPLACE FUNCTION insert_sample_p (
  input_message VARCHAR(255)
)
RETURNS INT AS $$
DECLARE
  sample_id INT;
BEGIN
  INSERT INTO sample (
    message
  )
  VALUES (
    input_message
  )
  RETURNING id INTO sample_id;

  RETURN sample_id;
END;$$
LANGUAGE 'plpgsql'
SECURITY DEFINER
SET search_path = public, pg_temp;

REVOKE ALL PRIVILEGES ON FUNCTION insert_sample_p(input_message VARCHAR(255)) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION insert_sample_p (
  input_message VARCHAR(255)
) TO sample_application;
