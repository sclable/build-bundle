def start_of_day: . + "T00:00:00Z" | fromdateiso8601;

to_entries
  | .[]
  | select(.value.start | start_of_day < now)
  | select(.value.end   | start_of_day > now)
  | .key[1:]
