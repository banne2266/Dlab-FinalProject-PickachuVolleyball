# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
create_project -in_memory -part xc7a35ticsg324-1L

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir C:/Users/zxcv3/Desktop/FP/lab10.cache/wt [current_project]
set_property parent.project_path C:/Users/zxcv3/Desktop/FP/lab10.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property board_part digilentinc.com:arty:part0:1.1 [current_project]
set_property ip_output_repo c:/Users/zxcv3/Desktop/FP/lab10.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_mem {
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/background.mem
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/ball20x20.mem
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/pika1.mem
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/cloud.mem
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/toright.mem
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/score.mem
}
read_verilog -library xil_defaultlib {
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/BCD_counter.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/LCD_module.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/clk_divider.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/debounce.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/sram.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/sram_ball.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/sram_cloud.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/sram_pika1.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/sramscore.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/vga_sync.v
  C:/Users/zxcv3/Desktop/FP/lab10.srcs/sources_1/lab10.v
}
# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc C:/Users/zxcv3/Desktop/FP/lab10.srcs/constrs_1/lab10.xdc
set_property used_in_implementation false [get_files C:/Users/zxcv3/Desktop/FP/lab10.srcs/constrs_1/lab10.xdc]

set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

synth_design -top lab10 -part xc7a35ticsg324-1L


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef lab10.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file lab10_utilization_synth.rpt -pb lab10_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
