include "schedule";

trigger[] | select(.tag == "lts") | to_entries | map("::set-output name=\(.key)::\(.value)") | join("\n")
