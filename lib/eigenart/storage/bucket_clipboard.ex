# defmodule Eigenart.Storage.BucketClipboard do
#   def process_storage_cmd(:put, clist, conf) when is_list(clist) do

#   end

#   def process_storage_cmd(:get, clist, conf) when is_list(clist) do
#   end

#   def process_storage_cmd(cmd, msg, conf) do
#     raise __MODULE__, {"unknown clipboard command: #{cmd}"}
#   end

#   def storage(conf) do
#     &process_storage_cmd(&1, &2, conf)
#   end
# end
