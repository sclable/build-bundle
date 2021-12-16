include "schedule";

def pipeline:
  map({ "\(.tag) (Ubuntu \(.ubuntu), Node \(.node), Java \(.java))": {
    cache: {},
    tags: ["medium"],
    image: {
      name: "gcr.io/kaniko-project/executor:debug",
      entrypoint: [""]
    },
    stage: "build",
    script: ([
        "/kaniko/executor",
        "--context=.",
        "--reproducible",
        "--cache=true",
        "--build-arg DOCKLE_VERSION=\(.dockle)",
        "--build-arg HADOLINT_VERSION=\(.hadolint)",
        "--build-arg JAVA_VERSION=\(.java)",
        "--build-arg NODE_VERSION=\(.node)",
        "--build-arg UBUNTU_VERSION=\(.ubuntu)",
        "--build-arg SELF=\(.self)"
      ] +
      ([
        .tag,
        "node-v\(.node)",
	"java-v\(.java)",
	"ubuntu-v\(.ubuntu)"
      ] | map("--destination \(env.IMAGE):" + .)))
    | join(" ")
  }}) | add;

def noop: {noop: {image: env.IMAGE, script: ["true"]}};

trigger | if length == 0 then noop else pipeline end
