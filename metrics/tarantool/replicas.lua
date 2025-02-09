local utils = require('metrics.utils')

local collectors_list = {}

local function update_replicas_metrics()
    if not utils.box_is_configured() then
        return
    end

    local current_box_info = box.info()

    if box.cfg.read_only then
        for k, v in pairs(current_box_info.vclock) do
            local replication_info = current_box_info.replication[k]
            if replication_info then
                local lsn = replication_info.lsn
                local metric_name = 'replication_replica_' .. k .. '_lsn'
                collectors_list[metric_name] = utils.set_gauge(metric_name, 'lsn for replica ' .. k, lsn - v)

                collectors_list.replication_lsn =
                    utils.set_gauge('replication_lsn', 'lsn for instance', lsn - v, {type = 'replica', id = k})
            end
        end
    else
        for k, v in pairs(current_box_info.replication) do
            if v.downstream ~= nil and v.downstream.vclock ~= nil then
                local lsn = v.downstream.vclock[current_box_info.id]
                if lsn ~= nil and current_box_info.lsn ~= nil then
                    local metric_name = 'replication_master_' .. k .. '_lsn'
                    collectors_list[metric_name] = utils.set_gauge(
                        metric_name,
                        'lsn for master ' .. k,
                        current_box_info.lsn - lsn
                    )
                    collectors_list.replication_lsn = utils.set_gauge(
                        'replication_lsn',
                        'lsn for instance',
                        current_box_info.lsn - lsn,
                        {type = 'master', id = k}
                    )
                end
            end
        end
    end
end

return {
    update = update_replicas_metrics,
    list = collectors_list,
}
