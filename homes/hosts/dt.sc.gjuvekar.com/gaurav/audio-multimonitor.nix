{ ... }: {
  xdg.configFile."pipewire/pipewire.conf.d/52-multimonitor-stereo.conf".text = ''
    context.modules = [
      {
        name = libpipewire-module-combine-stream
        args = {
          combine.mode = sink
          node.name = multimonitor_stereo
          node.description = "multimonitor_stereo"
          combine.latency-compensate = true
          combine.props = {
            audio.position = [ FL FR ]
            node.nick = "multimonitor_stereo"
          }
          stream.props = { stream.dont-remix = true }
          stream.rules = [
            {
              matches = [
                {
                  media.class = Audio/Sink
                  node.name = "alsa_output.pci-0000_01_00.1.left_monitor"
                }
              ]
              actions = {
                create-stream = {
                  combine.audio.position = [ FL FL ]
                  audio.position = [ FL FR ]
                }
              }
            }
            {
              matches = [
                {
                  media.class = Audio/Sink
                  node.name = "alsa_output.pci-0000_01_00.1.right_monitor"
                }
              ]
              actions = {
                create-stream = {
                  combine.audio.position = [ FR FR ]
                  audio.position = [ FL FR ]
                }
              }
            }
          ]
        }
      }
    ]
  '';
}
