# TEMPORARY: diagnoses the Firefox lag/disappearing cursor on the nvidia (max) profile.
# Logs X server stalls to ~/xstall.log together with the dGPU's runtime power state,
# so a freeze can be matched against "dGPU woke up" / "firefox started" / "picom started".
#   tail -f ~/xstall.log
# Toggle with the one line below (xstallLogger.enable). To remove it for good, delete this file
# and its import in profiles/max.nix.
{ config, pkgs, lib, ... }:
let
  cfg = config.xstallLogger;

  xstallLogger = pkgs.writers.writePython3Bin "xstall-logger"
    { libraries = [ pkgs.python3Packages.xlib ]; flakeIgnore = [ "E" "W" ]; }
    ''
      import os, time
      from Xlib import display

      LOG = "/home/lynaten/xstall.log"
      DGPU = "/sys/bus/pci/devices/0000:01:00.0/power/runtime_status"
      WATCH = ("firefox", "picom", "spotifast", "glxgears")
      RTT_MS, GAP_MS = 50, 100  # log round trips / sampling gaps slower than this


      def log(msg):
          with open(LOG, "a") as f:
              f.write("%s %s\n" % (time.strftime("%H:%M:%S"), msg))


      def dgpu():
          try:
              return open(DGPU).read().strip()
          except Exception:
              return "?"


      def procs():
          seen = set()
          for p in os.listdir("/proc"):
              if p.isdigit():
                  try:
                      c = open("/proc/%s/comm" % p).read().strip()
                  except Exception:
                      continue
                  for w in WATCH:
                      if c.startswith(w) or c.startswith("." + w):
                          seen.add(w)
          return seen


      d = display.Display()
      log("logger started, dgpu=%s" % dgpu())
      last = time.perf_counter()
      state, seen = dgpu(), procs()
      worst, hb = 0.0, time.time()
      tick = 0
      while True:
          t = time.perf_counter()
          gap = (t - last) * 1000
          last = t
          d.get_input_focus()
          rtt = (time.perf_counter() - t) * 1000
          worst = max(worst, rtt)
          if rtt > RTT_MS or gap > GAP_MS:
              log("STALL rtt=%.0fms gap=%.0fms dgpu=%s" % (rtt, gap, dgpu()))
          tick += 1
          if tick % 100 == 0:  # ~every 0.5s
              s = dgpu()
              if s != state:
                  log("dgpu %s -> %s" % (state, s))
                  state = s
              p = procs()
              for w in sorted(p - seen):
                  log("started: %s (dgpu=%s)" % (w, state))
              for w in sorted(seen - p):
                  log("exited: %s" % w)
              seen = p
          if time.time() - hb > 60:
              log("ok worst_rtt=%.1fms dgpu=%s" % (worst, state))
              worst, hb = 0.0, time.time()
          time.sleep(0.005)
    '';
in
{
  options.xstallLogger.enable = lib.mkEnableOption "the X stall logger (writes ~/xstall.log)";

  config = lib.mkMerge [
    {
      xstallLogger.enable = false; # <- toggle here
    }
    (lib.mkIf cfg.enable {
      systemd.user.services.xstall-logger = {
        description = "Temporary: log X server stalls vs dGPU power state";
        after = [ "default.target" "x11-setup.service" ];
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Environment = [ "DISPLAY=:0" ];
          ExecStart = "${xstallLogger}/bin/xstall-logger";
          Restart = "always";
          RestartSec = 3; # X may not be up yet at login
        };
      };
    })
  ];
}
