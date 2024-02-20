CREATE TABLE users (
                       id bigserial,
                       username varchar(64) not null ,
                       nickname varchar(64) not null ,
                       password varchar(128) not null default '',
                       phone varchar(16) not null default '',
                       email varchar(64) not null default '',
                       portrait varchar(255) not null default '' ,
                       roles varchar(255) not null ,
                       contacts varchar(1024) ,
                       maintainer smallint not null default 0,
                       create_at bigint not null default 0,
                       create_by varchar(64) not null default '',
                       update_at bigint not null default 0,
                       update_by varchar(64) not null default '',
                       PRIMARY KEY (id),
                       UNIQUE (username)
) ;


CREATE TABLE user_group (
                            id bigserial,
                            name varchar(128) not null default '',
                            note varchar(255) not null default '',
                            create_at bigint not null default 0,
                            create_by varchar(64) not null default '',
                            update_at bigint not null default 0,
                            update_by varchar(64) not null default '',
                            PRIMARY KEY (id)
) ;
CREATE INDEX user_group_create_by_idx ON user_group (create_by);
CREATE INDEX user_group_update_at_idx ON user_group (update_at);
CREATE TABLE user_group_member (
                                   id bigserial,
                                   group_id bigint  not null,
                                   user_id bigint  not null,
                                   PRIMARY KEY(id)
) ;
CREATE INDEX user_group_member_group_id_idx ON user_group_member (group_id);
CREATE INDEX user_group_member_user_id_idx ON user_group_member (user_id);

CREATE TABLE configs (
                         id bigserial,
                         ckey varchar(191) not null,
                         cval text not null default '',
                         PRIMARY KEY (id),
                         UNIQUE (ckey)
) ;

CREATE TABLE role (
                      id bigserial,
                      name varchar(191) not null default '',
                      note varchar(255) not null default '',
                      PRIMARY KEY (id),
                      UNIQUE (name)
) ;

CREATE TABLE role_operation(
                               id bigserial,
                               role_name varchar(128) not null,
                               operation varchar(191) not null,
                               PRIMARY KEY(id)
) ;
CREATE INDEX role_operation_role_name_idx ON role_operation (role_name);
CREATE INDEX role_operation_operation_idx ON role_operation (operation);


-- for alert_rule | collect_rule | mute | dashboard grouping
CREATE TABLE busi_group (
                            id bigserial,
                            name varchar(191) not null,
                            label_enable smallint not null default 0,
                            label_value varchar(191) not null default '' ,
                            create_at bigint not null default 0,
                            create_by varchar(64) not null default '',
                            update_at bigint not null default 0,
                            update_by varchar(64) not null default '',
                            PRIMARY KEY (id),
                            UNIQUE (name)
) ;


CREATE TABLE busi_group_member (
                                   id bigserial,
                                   busi_group_id bigint not null ,
                                   user_group_id bigint not null ,
                                   perm_flag char(2) not null ,
                                   PRIMARY KEY (id)
) ;
CREATE INDEX busi_group_member_busi_group_id_idx ON busi_group_member (busi_group_id);
CREATE INDEX busi_group_member_user_group_id_idx ON busi_group_member (user_group_id);


-- for dashboard new version
CREATE TABLE board (
                       id bigserial,
                       group_id bigint not null default 0 ,
                       name varchar(191) not null,
                       ident varchar(200) not null default '',
                       tags varchar(255) not null ,
                       public smallint not null default 0 ,
                       built_in smallint not null default 0 ,
                       hide smallint not null default 0 ,
                       create_at bigint not null default 0,
                       create_by varchar(64) not null default '',
                       update_at bigint not null default 0,
                       update_by varchar(64) not null default '',
                       PRIMARY KEY (id),
                       UNIQUE (group_id, name)
) ;
CREATE INDEX board_ident_idx ON board (ident);


-- for dashboard new version
CREATE TABLE board_payload (
                               id bigint  not null ,
                               payload text not null,
                               UNIQUE (id)
) ;

-- deprecated
CREATE TABLE dashboard (
                           id bigserial,
                           group_id bigint not null default 0 ,
                           name varchar(191) not null,
                           tags varchar(255) not null ,
                           configs varchar(8192) ,
                           create_at bigint not null default 0,
                           create_by varchar(64) not null default '',
                           update_at bigint not null default 0,
                           update_by varchar(64) not null default '',
                           PRIMARY KEY (id),
                           UNIQUE (group_id, name)
) ;

-- deprecated
-- auto create the first subclass 'Default chart group' of dashboard
CREATE TABLE chart_group (
                             id bigserial,
                             dashboard_id bigint  not null,
                             name varchar(255) not null,
                             weight int not null default 0,
                             PRIMARY KEY (id)
) ;
CREATE INDEX chart_group_dashboard_id_idx ON chart_group (dashboard_id);

-- deprecated
CREATE TABLE chart (
                       id bigserial,
                       group_id bigint  not null ,
                       configs text,
                       weight int not null default 0,
                       PRIMARY KEY (id)
) ;
CREATE INDEX chart_group_id_idx ON chart (group_id);

CREATE TABLE chart_share (
                             id bigserial,
                             cluster varchar(128) not null,
                             datasource_id bigint  not null default 0,
                             configs text,
                             create_at bigint not null default 0,
                             create_by varchar(64) not null default '',
                             primary key (id)
) ;
CREATE INDEX chart_share_create_at_idx ON chart_share (create_at);


CREATE TABLE alert_rule (
                            id bigserial,
                            group_id bigint not null default 0 ,
                            cate varchar(128) not null,
                            datasource_ids varchar(255) not null default '' ,
                            cluster varchar(128) not null,
                            name varchar(255) not null,
                            note varchar(1024) not null default '',
                            prod varchar(255) not null default '',
                            algorithm varchar(255) not null default '',
                            algo_params varchar(255),
                            delay int not null default 0,
                            severity smallint not null ,
                            disabled smallint not null ,
                            prom_for_duration int not null ,
                            rule_config text not null ,
                            prom_ql text not null ,
                            prom_eval_interval int not null ,
                            enable_stime varchar(255) not null default '00:00',
                            enable_etime varchar(255) not null default '23:59',
                            enable_days_of_week varchar(255) not null default '' ,
                            enable_in_bg smallint not null default 0 ,
                            notify_recovered smallint not null ,
                            notify_channels varchar(255) not null default '' ,
                            notify_groups varchar(255) not null default '' ,
                            notify_repeat_step int not null default 0 ,
                            notify_max_number int not null default 0 ,
                            recover_duration int not null default 0 ,
                            callbacks varchar(255) not null default '' ,
                            runbook_url varchar(255),
                            append_tags varchar(255) not null default '' ,
                            annotations text not null ,
                            extra_config text not null ,
                            create_at bigint not null default 0,
                            create_by varchar(64) not null default '',
                            update_at bigint not null default 0,
                            update_by varchar(64) not null default '',
                            PRIMARY KEY (id)
) ;
CREATE INDEX alert_rule_group_id_idx ON alert_rule (group_id);
CREATE INDEX alert_rule_update_at_idx ON alert_rule (update_at);
CREATE TABLE alert_mute (
                            id bigserial,
                            group_id bigint not null default 0 ,
                            prod varchar(255) not null default '',
                            note varchar(1024) not null default '',
                            cate varchar(128) not null,
                            cluster varchar(128) not null,
                            datasource_ids varchar(255) not null default '' ,
                            tags jsonb NOT NULL ,
                            cause varchar(255) not null default '',
                            btime bigint not null default 0 ,
                            etime bigint not null default 0 ,
                            disabled smallint not null default 0 ,
                            mute_time_type smallint not null default 0,
                            periodic_mutes varchar(4096) not null default '',
                            severities varchar(32) not null default '',
                            create_at bigint not null default 0,
                            create_by varchar(64) not null default '',
                            update_at bigint not null default 0,
                            update_by varchar(64) not null default '',
                            PRIMARY KEY (id)
) ;
CREATE INDEX alert_mute_group_id_idx ON alert_mute (group_id);
CREATE INDEX alert_mute_update_at_idx ON alert_mute (update_at);


CREATE TABLE alert_subscribe (
                                 id bigserial,
                                 name varchar(255) not null default '',
                                 disabled smallint not null default 0 ,
                                 group_id bigint not null default 0 ,
                                 prod varchar(255) not null default '',
                                 cate varchar(128) not null,
                                 datasource_ids varchar(255) not null default '' ,
                                 cluster varchar(128) not null,
                                 rule_id bigint not null default 0,
                                 severities varchar(32) not null default '',
                                 tags varchar(4096) not null default '' ,
                                 redefine_severity smallint default 0 ,
                                 new_severity smallint not null ,
                                 redefine_channels smallint default 0 ,
                                 new_channels varchar(255) not null default '' ,
                                 user_group_ids varchar(250) not null ,
                                 webhooks text not null,
                                 extra_config text not null,
                                 redefine_webhooks smallint default 0,
                                 for_duration bigint not null default 0,
                                 create_at bigint not null default 0,
                                 create_by varchar(64) not null default '',
                                 update_at bigint not null default 0,
                                 update_by varchar(64) not null default '',
                                 PRIMARY KEY (id)
) ;
CREATE INDEX alert_subscribe_group_id_idx ON alert_subscribe (group_id);
CREATE INDEX alert_subscribe_update_at_idx ON alert_subscribe (update_at);


CREATE TABLE target (
                        id bigserial,
                        group_id bigint not null default 0 ,
                        ident varchar(191) not null ,
                        note varchar(255) not null default '' ,
                        tags varchar(512) not null default '' ,
                        update_at bigint not null default 0,
                        PRIMARY KEY (id),
                        UNIQUE (ident)
) ;
CREATE INDEX target_group_id_idx ON target (group_id);

-- case1: target_idents; case2: target_tags
-- CREATE TABLE collect_rule (
--     id bigserial,
--     group_id bigint not null default 0 comment 'busi group id',
--     cluster varchar(128) not null,
--     target_idents varchar(512) not null default '' comment 'ident list, split by space',
--     target_tags varchar(512) not null default '' comment 'filter targets by tags, split by space',
--     name varchar(191) not null default '',
--     note varchar(255) not null default '',
--     step int not null,
--     type varchar(64) not null comment 'e.g. port proc log plugin',
--     data text not null,
--     append_tags varchar(255) not null default '' comment 'split by space: e.g. mod=n9e dept=cloud',
--     create_at bigint not null default 0,
--     create_by varchar(64) not null default '',
--     update_at bigint not null default 0,
--     update_by varchar(64) not null default '',
--     PRIMARY KEY (id),
--     KEY (group_id, type, name)
-- ) ;

CREATE TABLE metric_view (
                             id bigserial,
                             name varchar(191) not null default '',
                             cate smallint not null ,
                             configs varchar(8192) not null default '',
                             create_at bigint not null default 0,
                             create_by bigint not null default 0,
                             update_at bigint not null default 0,
                             PRIMARY KEY (id)
) ;
CREATE INDEX metric_view_create_by_idx ON metric_view (create_by);

CREATE TABLE recording_rule (
                                id bigserial,
                                group_id bigint not null default '0',
                                datasource_ids varchar(255) not null default '',
                                cluster varchar(128) not null,
                                name varchar(255) not null ,
                                note varchar(255) not null ,
                                disabled smallint not null default 0 ,
                                prom_ql varchar(8192) not null ,
                                prom_eval_interval int not null ,
                                append_tags varchar(255) default '' ,
                                query_configs text not null ,
                                create_at bigint default '0',
                                create_by varchar(64) default '',
                                update_at bigint default '0',
                                update_by varchar(64) default '',
                                PRIMARY KEY (id)
) ;
CREATE INDEX recording_rule_group_id_idx ON recording_rule (group_id);
CREATE INDEX recording_rule_update_at_idx ON recording_rule (update_at);


CREATE TABLE alert_aggr_view (
                                 id bigserial,
                                 name varchar(191) not null default '',
                                 rule varchar(2048) not null default '',
                                 cate smallint not null ,
                                 create_at bigint not null default 0,
                                 create_by bigint not null default 0,
                                 update_at bigint not null default 0,
                                 PRIMARY KEY (id)
) ;
CREATE INDEX alert_aggr_view_create_by_idx ON alert_aggr_view (create_by);

CREATE TABLE alert_cur_event (
                                 id bigint  not null ,
                                 cate varchar(128) not null,
                                 datasource_id bigint not null default 0 ,
                                 cluster varchar(128) not null,
                                 group_id bigint  not null ,
                                 group_name varchar(255) not null default '' ,
                                 hash varchar(64) not null ,
                                 rule_id bigint  not null,
                                 rule_name varchar(255) not null,
                                 rule_note varchar(2048) not null ,
                                 rule_prod varchar(255) not null default '',
                                 rule_algo varchar(255) not null default '',
                                 severity smallint not null ,
                                 prom_for_duration int not null ,
                                 prom_ql varchar(8192) not null ,
                                 prom_eval_interval int not null ,
                                 callbacks varchar(255) not null default '' ,
                                 runbook_url varchar(255),
                                 notify_recovered smallint not null ,
                                 notify_channels varchar(255) not null default '' ,
                                 notify_groups varchar(255) not null default '' ,
                                 notify_repeat_next bigint not null default 0 ,
                                 notify_cur_number int not null default 0 ,
                                 target_ident varchar(191) not null default '' ,
                                 target_note varchar(191) not null default '' ,
                                 first_trigger_time bigint,
                                 trigger_time bigint not null,
                                 trigger_value varchar(255) not null,
                                 annotations text not null ,
                                 rule_config text not null ,
                                 tags varchar(1024) not null default '' ,
                                 PRIMARY KEY (id)
) ;
CREATE INDEX alert_cur_event_hash_idx ON alert_cur_event (hash);
CREATE INDEX alert_cur_event_rule_id_idx ON alert_cur_event (rule_id);
CREATE INDEX alert_cur_event_tg_idx ON alert_cur_event (trigger_time, group_id);
CREATE INDEX alert_cur_event_nrn_idx ON alert_cur_event (notify_repeat_next);


CREATE TABLE alert_his_event (
                                 id bigserial,
                                 is_recovered smallint not null,
                                 cate varchar(128) not null,
                                 datasource_id bigint not null default 0 ,
                                 cluster varchar(128) not null,
                                 group_id bigint  not null ,
                                 group_name varchar(255) not null default '' ,
                                 hash varchar(64) not null ,
                                 rule_id bigint  not null,
                                 rule_name varchar(255) not null,
                                 rule_note varchar(2048) not null default 'alert rule note',
                                 rule_prod varchar(255) not null default '',
                                 rule_algo varchar(255) not null default '',
                                 severity smallint not null ,
                                 prom_for_duration int not null ,
                                 prom_ql varchar(8192) not null ,
                                 prom_eval_interval int not null ,
                                 callbacks varchar(255) not null default '' ,
                                 runbook_url varchar(255),
                                 notify_recovered smallint not null ,
                                 notify_channels varchar(255) not null default '' ,
                                 notify_groups varchar(255) not null default '' ,
                                 notify_cur_number int not null default 0 ,
                                 target_ident varchar(191) not null default '' ,
                                 target_note varchar(191) not null default '' ,
                                 first_trigger_time bigint,
                                 trigger_time bigint not null,
                                 trigger_value varchar(255) not null,
                                 recover_time bigint not null default 0,
                                 last_eval_time bigint not null default 0 ,
                                 tags varchar(1024) not null default '' ,
                                 annotations text not null ,
                                 rule_config text not null ,
                                 PRIMARY KEY (id)
) ;
CREATE INDEX alert_his_event_hash_idx ON alert_his_event (hash);
CREATE INDEX alert_his_event_rule_id_idx ON alert_his_event (rule_id);
CREATE INDEX alert_his_event_tg_idx ON alert_his_event (trigger_time, group_id);

CREATE TABLE task_tpl
(
    id        serial,
    group_id  int  not null ,
    title     varchar(255) not null default '',
    account   varchar(64)  not null,
    batch     int  not null default 0,
    tolerance int  not null default 0,
    timeout   int  not null default 0,
    pause     varchar(255) not null default '',
    script    text         not null,
    args      varchar(512) not null default '',
    tags      varchar(255) not null default '' ,
    create_at bigint not null default 0,
    create_by varchar(64) not null default '',
    update_at bigint not null default 0,
    update_by varchar(64) not null default '',
    PRIMARY KEY (id)
) ;
CREATE INDEX task_tpl_group_id_idx ON task_tpl (group_id);


CREATE TABLE task_tpl_host
(
    ii   serial,
    id   int  not null ,
    host varchar(128)  not null ,
    PRIMARY KEY (ii)
) ;
CREATE INDEX task_tpl_host_id_host_idx ON task_tpl_host (id, host);

CREATE TABLE task_record
(
    id bigint  not null ,
    event_id bigint not null default 0,
    group_id bigint not null ,
    ibex_address   varchar(128) not null,
    ibex_auth_user varchar(128) not null default '',
    ibex_auth_pass varchar(128) not null default '',
    title     varchar(255)    not null default '',
    account   varchar(64)     not null,
    batch     int     not null default 0,
    tolerance int     not null default 0,
    timeout   int     not null default 0,
    pause     varchar(255)    not null default '',
    script    text            not null,
    args      varchar(512)    not null default '',
    create_at bigint not null default 0,
    create_by varchar(64) not null default '',
    PRIMARY KEY (id)
) ;
CREATE INDEX task_record_cg_idx ON task_record (create_at, group_id);
CREATE INDEX task_record_create_by_idx ON task_record (create_by);
CREATE INDEX task_record_event_id_idx ON task_record (event_id);

CREATE TABLE alerting_engines
(
    id serial,
    instance varchar(128) not null default '' ,
    datasource_id bigint not null default 0 ,
    engine_cluster varchar(128) not null default '' ,
    clock bigint not null,
    PRIMARY KEY (id)
) ;

CREATE TABLE datasource
(
    id serial,
    name varchar(191) not null default '',
    description varchar(255) not null default '',
    category varchar(255) not null default '',
    plugin_id int  not null default 0,
    plugin_type varchar(255) not null default '',
    plugin_type_name varchar(255) not null default '',
    cluster_name varchar(255) not null default '',
    settings text not null,
    status varchar(255) not null default '',
    http varchar(4096) not null default '',
    auth varchar(8192) not null default '',
    created_at bigint not null default 0,
    created_by varchar(64) not null default '',
    updated_at bigint not null default 0,
    updated_by varchar(64) not null default '',
    UNIQUE (name),
    PRIMARY KEY (id)
) ;

CREATE TABLE builtin_cate (
                              id bigserial,
                              name varchar(191) not null,
                              user_id bigint not null default 0,
                              PRIMARY KEY (id)
) ;

CREATE TABLE notify_tpl (
                            id bigserial,
                            channel varchar(32) not null,
                            name varchar(255) not null,
                            content text not null,
                            PRIMARY KEY (id),
                            UNIQUE (channel)
) ;

CREATE TABLE sso_config (
                            id bigserial,
                            name varchar(191) not null,
                            content text not null,
                            PRIMARY KEY (id),
                            UNIQUE (name)
) ;


CREATE TABLE es_index_pattern (
                                  id bigserial,
                                  datasource_id bigint not null default 0,
                                  name varchar(191) not null,
                                  time_field varchar(128) not null default '@timestamp',
                                  allow_hide_system_indices smallint not null default 0,
                                  fields_format varchar(4096) not null default '',
                                  create_at bigint default '0',
                                  create_by varchar(64) default '',
                                  update_at bigint default '0',
                                  update_by varchar(64) default '',
                                  PRIMARY KEY (id),
                                  UNIQUE (datasource_id, name)
) ;


INSERT INTO "alert_aggr_view" VALUES (1, 'By BusiGroup, Severity', 'field:group_name::field:severity', 0, 0, 0, 0);
INSERT INTO "alert_aggr_view" VALUES (2, 'By RuleName', 'field:rule_name', 0, 0, 0, 0);

INSERT INTO "board" VALUES (2, 1, '宿主机监控', '', '', 1, 0, 0, 1689046781, 'root', 1689047078, 'root');

INSERT INTO "board_payload" VALUES (2, '{"links":[{"targetBlank":true,"title":"n9e","url":"https://n9e.github.io/"},{"targetBlank":true,"title":"author","url":"http://flashcat.cloud/"}],"panels":[{"collapsed":true,"id":"2b2de3d1-65c8-4c39-9bea-02b754e0d751","layout":{"h":1,"i":"2b2de3d1-65c8-4c39-9bea-02b754e0d751","isResizable":false,"w":24,"x":0,"y":0},"name":"单机概况","type":"row"},{"custom":{"calc":"lastNotNull","colSpan":1,"colorMode":"value","textMode":"value","textSize":{"value":30},"valueField":"Value"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"deec579b-3090-4344-a9a6-c1455c4a8e50","layout":{"h":3,"i":"deec579b-3090-4344-a9a6-c1455c4a8e50","isResizable":true,"w":6,"x":0,"y":1},"name":"启动时长（单位：天）","options":{"standardOptions":{"decimals":1,"util":"none"},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"valueMappings":[]},"targets":[{"expr":"system_uptime{ident=~\"$ident\"}/3600/24","refId":"A"}],"transformations":[{"id":"organize","options":{}}],"type":"stat","version":"3.0.0"},{"custom":{"calc":"lastNotNull","colSpan":1,"colorMode":"value","textMode":"value","textSize":{"value":30},"valueField":"Value"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"7a7bd5db-d12e-49f0-92a8-15958e99ee54","layout":{"h":3,"i":"7a7bd5db-d12e-49f0-92a8-15958e99ee54","isResizable":true,"w":6,"x":6,"y":1},"name":"CPU使用率","options":{"standardOptions":{"decimals":1,"util":"percent"},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"valueMappings":[{"match":{"from":0,"to":50},"result":{"color":"#129b22"},"type":"range"},{"match":{"from":50,"to":100},"result":{"color":"#f51919"},"type":"range"}]},"targets":[{"expr":"100-cpu_usage_idle{ident=~\"$ident\",cpu=\"cpu-total\"}","refId":"A"}],"transformations":[{"id":"organize","options":{}}],"type":"stat","version":"3.0.0"},{"custom":{"calc":"lastNotNull","colSpan":1,"colorMode":"value","textMode":"value","textSize":{"value":30}},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"8a814265-54ad-419c-8cb7-e1f84a242de0","layout":{"h":3,"i":"8a814265-54ad-419c-8cb7-e1f84a242de0","isResizable":true,"w":6,"x":12,"y":1},"name":"内存使用率","options":{"standardOptions":{"decimals":1,"util":"percent"},"valueMappings":[{"match":{"from":0,"to":50},"result":{"color":"#129b22"},"type":"range"},{"match":{"from":50,"to":100},"result":{"color":"#f51919"},"type":"range"}]},"targets":[{"expr":"mem_used_percent{ident=~\"$ident\"}","refId":"A"}],"type":"stat","version":"2.0.0"},{"custom":{"calc":"lastNotNull","colSpan":1,"colorMode":"value","textMode":"value","textSize":{"value":25}},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"d7d11972-5c5b-4bc6-98f8-bbbe9f018896","layout":{"h":3,"i":"d7d11972-5c5b-4bc6-98f8-bbbe9f018896","isResizable":true,"w":3,"x":18,"y":1},"name":"FD使用率","options":{"standardOptions":{"decimals":2,"util":"percent"},"valueMappings":[{"match":{"from":0,"to":50},"result":{"color":"#129b22"},"type":"range"},{"match":{"from":50,"to":100},"result":{"color":"#f51919"},"type":"range"}]},"targets":[{"expr":"linux_sysctl_fs_file_nr{ident=~\"$ident\"}/linux_sysctl_fs_file_max{ident=~\"$ident\"}*100","refId":"A"}],"type":"stat","version":"2.0.0"},{"custom":{"calc":"lastNotNull","colSpan":1,"colorMode":"value","textMode":"value","textSize":{"value":40}},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"209d3aba-5e02-4b8f-a364-65f20ba92a2c","layout":{"h":3,"i":"209d3aba-5e02-4b8f-a364-65f20ba92a2c","isResizable":true,"w":3,"x":21,"y":1},"name":"SWAP使用","options":{"standardOptions":{"decimals":1,"util":"bytesIEC"},"valueMappings":[]},"targets":[{"expr":"mem_swap_total{ident=~\"$ident\"}-mem_swap_free{ident=~\"$ident\"}","refId":"A"}],"type":"stat","version":"2.0.0"},{"custom":{"baseColor":"#9470FF","calc":"lastNotNull","serieWidth":20,"sortOrder":"desc"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"b3c5dd9d-e82a-4b15-8b23-c510e2bee152","layout":{"h":3,"i":"b3c5dd9d-e82a-4b15-8b23-c510e2bee152","isResizable":true,"w":8,"x":0,"y":4},"name":"磁盘使用率","options":{"standardOptions":{}},"targets":[{"expr":"disk_used_percent{ident=~\"$ident\"}","instant":false,"legend":"{{ident}}-{{path}}","refId":"A","step":60}],"transformations":[{"id":"organize","options":{}}],"type":"barGauge","version":"3.0.0"},{"custom":{"baseColor":"#9470FF","calc":"lastNotNull","serieWidth":20,"sortOrder":"desc"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"0de74cd9-cc74-4a96-bcb2-05d3a8bde2ea","layout":{"h":3,"i":"0de74cd9-cc74-4a96-bcb2-05d3a8bde2ea","isResizable":true,"w":8,"x":8,"y":4},"name":"inode使用率","options":{"standardOptions":{}},"targets":[{"expr":"disk_inodes_used{ident=~\"$ident\"}/disk_inodes_total{ident=~\"$ident\"}","instant":true,"legend":"{{ident}}-{{path}}","refId":"A"}],"transformations":[{"id":"organize","options":{}}],"type":"barGauge","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"59afa167-434d-496c-a3ef-ceff6db7c1f6","layout":{"h":3,"i":"59afa167-434d-496c-a3ef-ceff6db7c1f6","isResizable":true,"w":8,"x":16,"y":4},"name":"io_util","options":{"legend":{"displayMode":"hidden"},"standardOptions":{"decimals":1,"util":"percent"},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"rate(diskio_io_time{ident=~\"$ident\"}[1m])/10","legend":"{{ident}}-{{name}}","refId":"A"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"collapsed":true,"id":"aabb8263-1a9b-43fb-bee1-6c532f5012a3","layout":{"h":1,"i":"aabb8263-1a9b-43fb-bee1-6c532f5012a3","isResizable":false,"w":24,"x":0,"y":7},"name":"系统指标","type":"row"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"1b4da538-29d4-4c58-b3f4-773fabb8616c","layout":{"h":7,"i":"1b4da538-29d4-4c58-b3f4-773fabb8616c","isResizable":true,"w":8,"x":0,"y":8},"name":"进程总数","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null},{"color":"#fa2a05","value":2000}]},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"processes_total{ident=~\"$ident\"}","refId":"A"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"aa7adae0-ae3b-4e28-a8ce-801c65961552","layout":{"h":7,"i":"aa7adae0-ae3b-4e28-a8ce-801c65961552","isResizable":true,"w":8,"x":8,"y":8},"name":"上下文切换/中断","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"rate(kernel_context_switches{ident=~\"$ident\"}[1m])","legend":"{{ident}}-context_switches","refId":"A"},{"expr":"rate(kernel_interrupts{ident=~\"$ident\"}[1m])","legend":"{{ident}}-kernel_interrupts","refId":"B"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"71e22f58-5b9a-4604-bca8-55bcef59b5fe","layout":{"h":7,"i":"71e22f58-5b9a-4604-bca8-55bcef59b5fe","isResizable":true,"w":8,"x":16,"y":8},"name":"熵池大小","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null},{"color":"#f50505","value":100}]},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"kernel_entropy_avail{ident=~\"$ident\"}","legend":"{{ident}}-entropy_avail","refId":"A"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"collapsed":true,"id":"10f34f8f-f94d-4a28-9551-16e6667e3833","layout":{"h":1,"i":"10f34f8f-f94d-4a28-9551-16e6667e3833","isResizable":false,"w":24,"x":0,"y":15},"name":"CPU","type":"row"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"1559d880-7e26-4e42-9427-4e55fb6f67be","layout":{"h":7,"i":"1559d880-7e26-4e42-9427-4e55fb6f67be","isResizable":true,"w":8,"x":0,"y":16},"name":"CPU空闲率","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null},{"color":"#f20202","value":10}]},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"cpu_usage_idle{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}","refId":"A"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"043c26de-d19f-4fe8-a615-2b7c10ceb828","layout":{"h":7,"i":"043c26de-d19f-4fe8-a615-2b7c10ceb828","isResizable":true,"w":8,"x":8,"y":16},"name":"CPU使用率详情","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"cpu_usage_guest{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}-cpu_usage_guest","refId":"A"},{"expr":"cpu_usage_iowait{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}-cpu_usage_iowait","refId":"B"},{"expr":"cpu_usage_user{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}-cpu_usage_user","refId":"C"},{"expr":"cpu_usage_system{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}-cpu_usage_system","refId":"D"},{"expr":"cpu_usage_irq{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}-cpu_usage_irq","refId":"E"},{"expr":"cpu_usage_softirq{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}-cpu_usage_softirq","refId":"F"},{"expr":"cpu_usage_nice{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}-cpu_usage_nice","refId":"G"},{"expr":"cpu_usage_steal{ident=~\"$ident\",cpu=\"cpu-total\"}","legend":"{{ident}}-cpu_usage_steal","refId":"H"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"lineInterpolation":"smooth","stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"a420ce25-6968-47f8-8335-60cde70fd062","layout":{"h":7,"i":"a420ce25-6968-47f8-8335-60cde70fd062","isResizable":true,"w":8,"x":16,"y":16},"name":"CPU负载","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"system_load15{ident=~\"$ident\"}","refId":"A"},{"expr":"system_load1{ident=~\"$ident\"}","refId":"B"},{"expr":"system_load5{ident=~\"$ident\"}","refId":"C"}],"type":"timeseries","version":"2.0.0"},{"collapsed":true,"id":"b7a3c99f-a796-4b76-89b5-cbddd566f91c","layout":{"h":1,"i":"b7a3c99f-a796-4b76-89b5-cbddd566f91c","isResizable":false,"w":24,"x":0,"y":23},"name":"内存详情","type":"row"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"lineInterpolation":"smooth","stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","description":"内存指标可参考链接 [/PROC/MEMINFO之谜](http://linuxperf.com/?p=142) ","id":"239aacdf-1982-428b-b240-57f4ce7f946d","layout":{"h":7,"i":"239aacdf-1982-428b-b240-57f4ce7f946d","isResizable":true,"w":12,"x":0,"y":24},"name":"用户态内存使用","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"mem_active{ident=~\"$ident\"}","refId":"A"},{"expr":"mem_cached{ident=~\"$ident\"}","refId":"B"},{"expr":"mem_buffered{ident=~\"$ident\"}","refId":"C"},{"expr":"mem_inactive{ident=~\"$ident\"}","refId":"D"},{"expr":"mem_mapped{ident=~\"$ident\"}","refId":"E"},{"expr":"mem_shared{ident=~\"$ident\"}","refId":"F"},{"expr":"mem_swap_cached{ident=~\"$ident\"}","refId":"G"}],"type":"timeseries","version":"2.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"lineInterpolation":"smooth","stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"00ed6e4d-c979-4938-a20e-56d42ca452cf","layout":{"h":7,"i":"00ed6e4d-c979-4938-a20e-56d42ca452cf","isResizable":true,"w":12,"x":12,"y":24},"name":"内核态内存使用","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"mem_slab{ident=~\"$ident\"}","refId":"A"},{"expr":"mem_sreclaimable{ident=~\"$ident\"}","refId":"B"},{"expr":"mem_sunreclaim{ident=~\"$ident\"}","refId":"C"},{"expr":"mem_vmalloc_used{ident=~\"$ident\"}","refId":"D"},{"expr":"mem_vmalloc_chunk{ident=~\"$ident\"}","refId":"E"}],"type":"timeseries","version":"2.0.0"},{"collapsed":true,"id":"842a8c48-0e93-40bf-8f28-1b2f837e5c19","layout":{"h":1,"i":"842a8c48-0e93-40bf-8f28-1b2f837e5c19","isResizable":false,"w":24,"x":0,"y":31},"name":"磁盘详情","type":"row"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"lineInterpolation":"smooth","stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"bc894871-1c03-4d12-91be-6867f394a8a6","layout":{"h":7,"i":"bc894871-1c03-4d12-91be-6867f394a8a6","isResizable":true,"w":8,"x":0,"y":32},"name":"磁盘空间","options":{"legend":{"displayMode":"hidden"},"standardOptions":{"decimals":null,"util":"bytesIEC"},"thresholds":{},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"disk_free{ident=~\"$ident\"}","refId":"A"},{"expr":"disk_total{ident=~\"$ident\"}","refId":"B"},{"expr":"disk_used{ident=~\"$ident\"}","refId":"C"}],"type":"timeseries","version":"2.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"lineInterpolation":"smooth","stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"d825671f-7dc5-46a2-89dc-4fff084a3ae0","layout":{"h":7,"i":"d825671f-7dc5-46a2-89dc-4fff084a3ae0","isResizable":true,"w":8,"x":8,"y":32},"name":"fd使用","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"linux_sysctl_fs_file_max{ident=~\"$ident\"}","refId":"A"},{"expr":"linux_sysctl_fs_file_nr{ident=~\"$ident\"}","refId":"B"}],"type":"timeseries","version":"2.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"d27b522f-9c70-42f2-9e31-fed3816fd675","layout":{"h":7,"i":"d27b522f-9c70-42f2-9e31-fed3816fd675","isResizable":true,"w":8,"x":16,"y":32},"name":"inode","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"disk_inodes_total{ident=~\"$ident\",path!~\"/var.*\"}","legend":"","refId":"A"},{"expr":"disk_inodes_used{ident=~\"$ident\",path!~\"/var.*\"}","legend":"","refId":"B"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"f645741e-c632-4685-b267-c7ad26b5c10e","layout":{"h":7,"i":"f645741e-c632-4685-b267-c7ad26b5c10e","isResizable":true,"w":8,"x":0,"y":39},"name":"IOPS","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"rate(diskio_reads{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{name}}-read","refId":"A"},{"expr":"rate(diskio_writes{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{name}}-writes","refId":"B"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"bbd1ebda-99f6-419c-90a5-5f84973976dd","layout":{"h":7,"i":"bbd1ebda-99f6-419c-90a5-5f84973976dd","isResizable":true,"w":8,"x":8,"y":39},"name":"IO吞吐量","options":{"legend":{"displayMode":"hidden"},"standardOptions":{"decimals":0,"util":"bytesIEC"},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"rate(diskio_read_bytes{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{name}}-read","refId":"A"},{"expr":"rate(diskio_write_bytes{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{name}}-writes","refId":"B"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"d6b45598-54c6-4b36-a896-0a7529ac21f8","layout":{"h":7,"i":"d6b45598-54c6-4b36-a896-0a7529ac21f8","isResizable":true,"w":8,"x":16,"y":39},"name":"iowait","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"rate(diskio_write_time{ident=~\"$ident\"}[1m])/rate(diskio_writes{ident=~\"$ident\"}[1m])+rate(diskio_read_time{ident=~\"$ident\"}[1m])/rate(diskio_reads{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{name}}","refId":"A"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"collapsed":true,"id":"307152d2-708c-4736-98cf-08b886cbf7f2","layout":{"h":1,"i":"307152d2-708c-4736-98cf-08b886cbf7f2","isResizable":false,"w":24,"x":0,"y":46},"name":"网络详情","type":"row"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"f2ee5d32-737c-4095-b6b7-b15b778ffdb9","layout":{"h":7,"i":"f2ee5d32-737c-4095-b6b7-b15b778ffdb9","isResizable":true,"w":6,"x":0,"y":47},"name":"网络流量","options":{"legend":{"displayMode":"hidden"},"standardOptions":{"decimals":0,"util":"bitsIEC"},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"rate(net_bytes_recv{ident=~\"$ident\"}[1m])*8","legend":"{{ident}}-{{interface}}-recv","refId":"A"},{"expr":"rate(net_bytes_sent{ident=~\"$ident\"}[1m])*8","legend":"{{ident}}-{{interface}}-sent","refId":"B"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"9113323a-98f5-4bff-a8ce-3b459e7e2190","layout":{"h":7,"i":"9113323a-98f5-4bff-a8ce-3b459e7e2190","isResizable":true,"w":6,"x":6,"y":47},"name":"packets","options":{"legend":{"displayMode":"hidden"},"standardOptions":{"decimals":0},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"rate(net_packets_recv{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{interface}}-recv","refId":"A"},{"expr":"rate(net_packets_sent{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{interface}}-sent","refId":"B"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"9634c41c-e124-4d7f-9406-0f86753e8d70","layout":{"h":7,"i":"9634c41c-e124-4d7f-9406-0f86753e8d70","isResizable":true,"w":6,"x":12,"y":47},"name":"error","options":{"legend":{"displayMode":"hidden"},"standardOptions":{"decimals":0},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"rate(net_err_in{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{interface}}-in","refId":"A"},{"expr":"rate(net_err_out{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{interface}}-out","refId":"B"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"gradientMode":"none","lineInterpolation":"smooth","lineWidth":1,"scaleDistribution":{"type":"linear"},"spanNulls":false,"stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"4123f4c1-bf8e-400e-b267-8d7f6a92691a","layout":{"h":7,"i":"4123f4c1-bf8e-400e-b267-8d7f6a92691a","isResizable":true,"w":6,"x":18,"y":47},"name":"drop","options":{"legend":{"displayMode":"hidden"},"standardOptions":{"decimals":0},"thresholds":{"steps":[{"color":"#634CD9","type":"base","value":null}]},"tooltip":{"mode":"all","sort":"desc"}},"targets":[{"expr":"rate(net_drop_in{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{interface}}-in","refId":"A"},{"expr":"rate(net_drop_out{ident=~\"$ident\"}[1m])","legend":"{{ident}}-{{interface}}-out","refId":"B"}],"transformations":[{"id":"organize","options":{}}],"type":"timeseries","version":"3.0.0"},{"custom":{"drawStyle":"lines","fillOpacity":0.5,"lineInterpolation":"smooth","stack":"off"},"datasourceCate":"prometheus","datasourceValue":"${prom}","id":"cfb80689-de7b-47fb-9155-052b796dd7f5","layout":{"h":7,"i":"cfb80689-de7b-47fb-9155-052b796dd7f5","isResizable":true,"w":24,"x":0,"y":54},"name":"tcp","options":{"legend":{"displayMode":"hidden"},"standardOptions":{},"thresholds":{},"tooltip":{"mode":"all","sort":"none"}},"targets":[{"expr":"netstat_tcp_established{ident=~\"$ident\"}","refId":"A"},{"expr":"netstat_tcp_listen{ident=~\"$ident\"}","refId":"B"},{"expr":"netstat_tcp_time_wait{ident=~\"$ident\"}","refId":"C"}],"type":"timeseries","version":"2.0.0"}],"var":[{"definition":"prometheus","name":"prom","type":"datasource"},{"allOption":true,"datasource":{"cate":"prometheus","value":"${prom}"},"definition":"label_values(system_load1,ident)","multi":true,"name":"ident","type":"query"}],"version":"3.0.0"}');

INSERT INTO "busi_group" VALUES (1, 'Default Busi Group', 0, '', 1688458902, 'root', 1688458902, 'root');

INSERT INTO "busi_group_member" VALUES (1, 1, 1, 'rw');

INSERT INTO "chart_share" VALUES (1, '', 0, '{"dataProps":{"type":"timeseries","version":"3.0.0","name":"procstat_cpu_usage_total","range":{"start":"now-1h","end":"now"},"custom":{"drawStyle":"lines","fillOpacity":0,"stack":"hidden","lineInterpolation":"smooth"},"options":{"legend":{"displayMode":"table"},"tooltip":{"mode":"all","sort":"desc"},"standardOptions":{"util":"none"}},"targets":[{"expr":"procstat_cpu_usage_total"}],"datasourceCate":"prometheus","datasourceName":"prometheus","datasourceValue":1}}', 1688462659, 'root');

INSERT INTO "configs" VALUES (1, 'notify_channel', '[{"name":"dingtalk","ident":"dingtalk","hide":false,"built_in":true},{"name":"wecom","ident":"wecom","hide":false,"built_in":true},{"name":"feishu","ident":"feishu","hide":false,"built_in":true},{"name":"mm","ident":"mm","hide":false,"built_in":true},{"name":"telegram","ident":"telegram","hide":false,"built_in":true},{"name":"email","ident":"email","hide":false,"built_in":true},{"name":"feishucard","ident":"feishucard","hide":false,"built_in":true}]');
INSERT INTO "configs" VALUES (2, 'notify_contact', '[{"name":"dingtalk_robot_token","ident":"dingtalk_robot_token","hide":false,"built_in":true},{"name":"wecom_robot_token","ident":"wecom_robot_token","hide":false,"built_in":true},{"name":"feishu_robot_token","ident":"feishu_robot_token","hide":false,"built_in":true},{"name":"mm_webhook_url","ident":"mm_webhook_url","hide":false,"built_in":true},{"name":"telegram_robot_token","ident":"telegram_robot_token","hide":false,"built_in":true}]');

INSERT INTO "datasource" VALUES (1, 'prometheus', '', '', 0, 'prometheus', '', 'default', '{}', 'enabled', '{"timeout":10000,"dial_timeout":0,"tls":{"skip_tls_verify":false},"max_idle_conns_per_host":0,"url":"http://prometheus:9090/","headers":{}}', '{"basic_auth":false,"basic_auth_user":"","basic_auth_password":""}', 1688459305, 'root', 1688459305, 'root');

INSERT INTO "metric_view" VALUES (1, 'Host View', 0, '{"filters":[{"oper":"=","label":"__name__","value":"cpu_usage_idle"}],"dynamicLabels":[],"dimensionLabels":[{"label":"ident","value":""}]}', 0, 0, 0);

INSERT INTO "notify_tpl" VALUES (1, 'mm', 'mm', '级别状态: S{{.Severity}} {{if .IsRecovered}}Recovered{{else}}Triggered{{end}}
规则名称: {{.RuleName}}{{if .RuleNote}}
规则备注: {{.RuleNote}}{{end}}
监控指标: {{.TagsJSON}}
{{if .IsRecovered}}恢复时间：{{timeformat .LastEvalTime}}{{else}}触发时间: {{timeformat .TriggerTime}}
触发时值: {{.TriggerValue}}{{end}}
发送时间: {{timestamp}}');
INSERT INTO "notify_tpl" VALUES (2, 'telegram', 'telegram', '**级别状态**: {{if .IsRecovered}}<font color="info">S{{.Severity}} Recovered</font>{{else}}<font color="warning">S{{.Severity}} Triggered</font>{{end}}
**规则标题**: {{.RuleName}}{{if .RuleNote}}
**规则备注**: {{.RuleNote}}{{end}}{{if .TargetIdent}}
**监控对象**: {{.TargetIdent}}{{end}}
**监控指标**: {{.TagsJSON}}{{if not .IsRecovered}}
**触发时值**: {{.TriggerValue}}{{end}}
{{if .IsRecovered}}**恢复时间**: {{timeformat .LastEvalTime}}{{else}}**首次触发时间**: {{timeformat .FirstTriggerTime}}{{end}}
{{$time_duration := sub now.Unix .FirstTriggerTime }}{{if .IsRecovered}}{{$time_duration = sub .LastEvalTime .FirstTriggerTime }}{{end}}**持续时长**: {{humanizeDurationInterface $time_duration}}
**发送时间**: {{timestamp}}');
INSERT INTO "notify_tpl" VALUES (3, 'wecom', 'wecom', '**级别状态**: {{if .IsRecovered}}<font color="info">S{{.Severity}} Recovered</font>{{else}}<font color="warning">S{{.Severity}} Triggered</font>{{end}}
**规则标题**: {{.RuleName}}{{if .RuleNote}}
**规则备注**: {{.RuleNote}}{{end}}{{if .TargetIdent}}
**监控对象**: {{.TargetIdent}}{{end}}
**监控指标**: {{.TagsJSON}}{{if not .IsRecovered}}
**触发时值**: {{.TriggerValue}}{{end}}
{{if .IsRecovered}}**恢复时间**: {{timeformat .LastEvalTime}}{{else}}**首次触发时间**: {{timeformat .FirstTriggerTime}}{{end}}
{{$time_duration := sub now.Unix .FirstTriggerTime }}{{if .IsRecovered}}{{$time_duration = sub .LastEvalTime .FirstTriggerTime }}{{end}}**持续时长**: {{humanizeDurationInterface $time_duration}}
**发送时间**: {{timestamp}}');
INSERT INTO "notify_tpl" VALUES (4, 'dingtalk', 'dingtalk', '#### {{if .IsRecovered}}<font color="#008800">S{{.Severity}} - Recovered - {{.RuleName}}</font>{{else}}<font color="#FF0000">S{{.Severity}} - Triggered - {{.RuleName}}</font>{{end}}

---

- **规则标题**: {{.RuleName}}{{if .RuleNote}}
- **规则备注**: {{.RuleNote}}{{end}}
{{if not .IsRecovered}}- **触发时值**: {{.TriggerValue}}{{end}}
{{if .TargetIdent}}- **监控对象**: {{.TargetIdent}}{{end}}
- **监控指标**: {{.TagsJSON}}
- {{if .IsRecovered}}**恢复时间**: {{timeformat .LastEvalTime}}{{else}}**触发时间**: {{timeformat .TriggerTime}}{{end}}
- **发送时间**: {{timestamp}}
	');
INSERT INTO "notify_tpl" VALUES (5, 'email', 'email', '<!DOCTYPE html>
	<html lang="en">
	<head>
		<meta charset="UTF-8">
		<meta http-equiv="X-UA-Compatible" content="ie=edge">
		<title>夜莺告警通知</title>
		<style type="text/css">
			.wrapper {
				background-color: #f8f8f8;
				padding: 15px;
				height: 100%;
			}
			.main {
				width: 600px;
				padding: 30px;
				margin: 0 auto;
				background-color: #fff;
				font-size: 12px;
				font-family: verdana,''Microsoft YaHei'',Consolas,''Deja Vu Sans Mono'',''Bitstream Vera Sans Mono'';
			}
			header {
				border-radius: 2px 2px 0 0;
			}
			header .title {
				font-size: 14px;
				color: #333333;
				margin: 0;
			}
			header .sub-desc {
				color: #333;
				font-size: 14px;
				margin-top: 6px;
				margin-bottom: 0;
			}
			hr {
				margin: 20px 0;
				height: 0;
				border: none;
				border-top: 1px solid #e5e5e5;
			}
			em {
				font-weight: 600;
			}
			table {
				margin: 20px 0;
				width: 100%;
			}

			table tbody tr{
				font-weight: 200;
				font-size: 12px;
				color: #666;
				height: 32px;
			}

			.succ {
				background-color: green;
				color: #fff;
			}

			.fail {
				background-color: red;
				color: #fff;
			}

			.succ th, .succ td, .fail th, .fail td {
				color: #fff;
			}

			table tbody tr th {
				width: 80px;
				text-align: right;
			}
			.text-right {
				text-align: right;
			}
			.body {
				margin-top: 24px;
			}
			.body-text {
				color: #666666;
				-webkit-font-smoothing: antialiased;
			}
			.body-extra {
				-webkit-font-smoothing: antialiased;
			}
			.body-extra.text-right a {
				text-decoration: none;
				color: #333;
			}
			.body-extra.text-right a:hover {
				color: #666;
			}
			.button {
				width: 200px;
				height: 50px;
				margin-top: 20px;
				text-align: center;
				border-radius: 2px;
				background: #2D77EE;
				line-height: 50px;
				font-size: 20px;
				color: #FFFFFF;
				cursor: pointer;
			}
			.button:hover {
				background: rgb(25, 115, 255);
				border-color: rgb(25, 115, 255);
				color: #fff;
			}
			footer {
				margin-top: 10px;
				text-align: right;
			}
			.footer-logo {
				text-align: right;
			}
			.footer-logo-image {
				width: 108px;
				height: 27px;
				margin-right: 10px;
			}
			.copyright {
				margin-top: 10px;
				font-size: 12px;
				text-align: right;
				color: #999;
				-webkit-font-smoothing: antialiased;
			}
		</style>
	</head>
	<body>
	<div class="wrapper">
		<div class="main">
			<header>
				<h3 class="title">{{.RuleName}}</h3>
				<p class="sub-desc"></p>
			</header>

			<hr>

			<div class="body">
				<table cellspacing="0" cellpadding="0" border="0">
					<tbody>
					{{if .IsRecovered}}
					<tr class="succ">
						<th>级别状态：</th>
						<td>S{{.Severity}} Recovered</td>
					</tr>
					{{else}}
					<tr class="fail">
						<th>级别状态：</th>
						<td>S{{.Severity}} Triggered</td>
					</tr>
					{{end}}

					<tr>
						<th>策略备注：</th>
						<td>{{.RuleNote}}</td>
					</tr>
					<tr>
						<th>设备备注：</th>
						<td>{{.TargetNote}}</td>
					</tr>
					{{if not .IsRecovered}}
					<tr>
						<th>触发时值：</th>
						<td>{{.TriggerValue}}</td>
					</tr>
					{{end}}

					{{if .TargetIdent}}
					<tr>
						<th>监控对象：</th>
						<td>{{.TargetIdent}}</td>
					</tr>
					{{end}}
					<tr>
						<th>监控指标：</th>
						<td>{{.TagsJSON}}</td>
					</tr>

					{{if .IsRecovered}}
					<tr>
						<th>恢复时间：</th>
						<td>{{timeformat .LastEvalTime}}</td>
					</tr>
					{{else}}
					<tr>
						<th>触发时间：</th>
						<td>
							{{timeformat .TriggerTime}}
						</td>
					</tr>
					{{end}}

					<tr>
						<th>发送时间：</th>
						<td>
							{{timestamp}}
						</td>
					</tr>
					</tbody>
				</table>

				<hr>

				<footer>
					<div class="copyright" style="font-style: italic">
						我们希望与您一起，将监控这个事情，做到极致！
					</div>
				</footer>
			</div>
		</div>
	</div>
	</body>
	</html>');
INSERT INTO "notify_tpl" VALUES (6, 'feishu', 'feishu', '级别状态: S{{.Severity}} {{if .IsRecovered}}Recovered{{else}}Triggered{{end}}
规则名称: {{.RuleName}}{{if .RuleNote}}
规则备注: {{.RuleNote}}{{end}}
监控指标: {{.TagsJSON}}
{{if .IsRecovered}}恢复时间：{{timeformat .LastEvalTime}}{{else}}触发时间: {{timeformat .TriggerTime}}
触发时值: {{.TriggerValue}}{{end}}
发送时间: {{timestamp}}');
INSERT INTO "notify_tpl" VALUES (7, 'feishucard', 'feishucard', '{{ if .IsRecovered }}
{{- if ne .Cate "host"}}
**告警集群:** {{.Cluster}}{{end}}
**级别状态:** S{{.Severity}} Recovered
**告警名称:** {{.RuleName}}
**恢复时间:** {{timeformat .LastEvalTime}}
**告警描述:** **服务已恢复**
{{- else }}
{{- if ne .Cate "host"}}
**告警集群:** {{.Cluster}}{{end}}
**级别状态:** S{{.Severity}} Triggered
**告警名称:** {{.RuleName}}
**触发时间:** {{timeformat .TriggerTime}}
**发送时间:** {{timestamp}}
**触发时值:** {{.TriggerValue}}
{{if .RuleNote }}**告警描述:** **{{.RuleNote}}**{{end}}
{{- end -}}');
INSERT INTO "notify_tpl" VALUES (8, 'mailsubject', 'mailsubject', '{{if .IsRecovered}}Recovered{{else}}Triggered{{end}}: {{.RuleName}} {{.TagsJSON}}');

INSERT INTO "role" VALUES (1, 'Admin', 'Administrator role');
INSERT INTO "role" VALUES (2, 'Standard', 'Ordinary user role');
INSERT INTO "role" VALUES (3, 'Guest', 'Readonly user role');

INSERT INTO "role_operation" VALUES (7, 'Standard', '/metric/explorer');
INSERT INTO "role_operation" VALUES (8, 'Standard', '/object/explorer');
INSERT INTO "role_operation" VALUES (9, 'Standard', '/log/explorer');
INSERT INTO "role_operation" VALUES (10, 'Standard', '/trace/explorer');
INSERT INTO "role_operation" VALUES (11, 'Standard', '/help/version');
INSERT INTO "role_operation" VALUES (12, 'Standard', '/help/contact');
INSERT INTO "role_operation" VALUES (13, 'Standard', '/help/servers');
INSERT INTO "role_operation" VALUES (14, 'Standard', '/help/migrate');
INSERT INTO "role_operation" VALUES (15, 'Standard', '/alert-rules-built-in');
INSERT INTO "role_operation" VALUES (16, 'Standard', '/dashboards-built-in');
INSERT INTO "role_operation" VALUES (17, 'Standard', '/trace/dependencies');
INSERT INTO "role_operation" VALUES (18, 'Admin', '/help/source');
INSERT INTO "role_operation" VALUES (19, 'Admin', '/help/sso');
INSERT INTO "role_operation" VALUES (20, 'Admin', '/help/notification-tpls');
INSERT INTO "role_operation" VALUES (21, 'Admin', '/help/notification-settings');
INSERT INTO "role_operation" VALUES (22, 'Standard', '/users');
INSERT INTO "role_operation" VALUES (23, 'Standard', '/user-groups');
INSERT INTO "role_operation" VALUES (24, 'Standard', '/user-groups/add');
INSERT INTO "role_operation" VALUES (25, 'Standard', '/user-groups/put');
INSERT INTO "role_operation" VALUES (26, 'Standard', '/user-groups/del');
INSERT INTO "role_operation" VALUES (27, 'Standard', '/busi-groups');
INSERT INTO "role_operation" VALUES (28, 'Standard', '/busi-groups/add');
INSERT INTO "role_operation" VALUES (29, 'Standard', '/busi-groups/put');
INSERT INTO "role_operation" VALUES (30, 'Standard', '/busi-groups/del');
INSERT INTO "role_operation" VALUES (31, 'Standard', '/targets');
INSERT INTO "role_operation" VALUES (32, 'Standard', '/targets/add');
INSERT INTO "role_operation" VALUES (33, 'Standard', '/targets/put');
INSERT INTO "role_operation" VALUES (34, 'Standard', '/targets/del');
INSERT INTO "role_operation" VALUES (35, 'Standard', '/dashboards');
INSERT INTO "role_operation" VALUES (36, 'Standard', '/dashboards/add');
INSERT INTO "role_operation" VALUES (37, 'Standard', '/dashboards/put');
INSERT INTO "role_operation" VALUES (38, 'Standard', '/dashboards/del');
INSERT INTO "role_operation" VALUES (39, 'Standard', '/alert-rules');
INSERT INTO "role_operation" VALUES (40, 'Standard', '/alert-rules/add');
INSERT INTO "role_operation" VALUES (41, 'Standard', '/alert-rules/put');
INSERT INTO "role_operation" VALUES (42, 'Standard', '/alert-rules/del');
INSERT INTO "role_operation" VALUES (43, 'Standard', '/alert-mutes');
INSERT INTO "role_operation" VALUES (44, 'Standard', '/alert-mutes/add');
INSERT INTO "role_operation" VALUES (45, 'Standard', '/alert-mutes/del');
INSERT INTO "role_operation" VALUES (46, 'Standard', '/alert-subscribes');
INSERT INTO "role_operation" VALUES (47, 'Standard', '/alert-subscribes/add');
INSERT INTO "role_operation" VALUES (48, 'Standard', '/alert-subscribes/put');
INSERT INTO "role_operation" VALUES (49, 'Standard', '/alert-subscribes/del');
INSERT INTO "role_operation" VALUES (50, 'Standard', '/alert-cur-events');
INSERT INTO "role_operation" VALUES (51, 'Standard', '/alert-cur-events/del');
INSERT INTO "role_operation" VALUES (52, 'Standard', '/alert-his-events');
INSERT INTO "role_operation" VALUES (53, 'Standard', '/job-tpls');
INSERT INTO "role_operation" VALUES (54, 'Standard', '/job-tpls/add');
INSERT INTO "role_operation" VALUES (55, 'Standard', '/job-tpls/put');
INSERT INTO "role_operation" VALUES (56, 'Standard', '/job-tpls/del');
INSERT INTO "role_operation" VALUES (57, 'Standard', '/job-tasks');
INSERT INTO "role_operation" VALUES (58, 'Standard', '/job-tasks/add');
INSERT INTO "role_operation" VALUES (59, 'Standard', '/job-tasks/put');
INSERT INTO "role_operation" VALUES (60, 'Standard', '/recording-rules');
INSERT INTO "role_operation" VALUES (61, 'Standard', '/recording-rules/add');
INSERT INTO "role_operation" VALUES (62, 'Standard', '/recording-rules/put');
INSERT INTO "role_operation" VALUES (63, 'Standard', '/recording-rules/del');
INSERT INTO "role_operation" VALUES (64, 'Guest', '/help/version');
INSERT INTO "role_operation" VALUES (65, 'Guest', '/log/explorer');
INSERT INTO "role_operation" VALUES (66, 'Guest', '/metric/explorer');
INSERT INTO "role_operation" VALUES (67, 'Guest', '/object/explorer');
INSERT INTO "role_operation" VALUES (68, 'Guest', '/trace/explorer');
INSERT INTO "role_operation" VALUES (69, 'Guest', '/dashboards');
INSERT INTO "role_operation" VALUES (70, 'Guest', '/dashboards/add');
INSERT INTO "role_operation" VALUES (71, 'Guest', '/dashboards/put');
INSERT INTO "role_operation" VALUES (72, 'Guest', '/dashboards/del');
INSERT INTO "role_operation" VALUES (73, 'Guest', '/dashboards-built-in');
INSERT INTO "role_operation" VALUES (74, 'Guest', '/alert-rules');
INSERT INTO "role_operation" VALUES (75, 'Guest', '/alert-rules/add');
INSERT INTO "role_operation" VALUES (76, 'Guest', '/alert-rules/put');
INSERT INTO "role_operation" VALUES (77, 'Guest', '/alert-rules/del');
INSERT INTO "role_operation" VALUES (78, 'Guest', '/alert-rules-built-in');
INSERT INTO "role_operation" VALUES (79, 'Guest', '/alert-mutes');
INSERT INTO "role_operation" VALUES (80, 'Guest', '/alert-mutes/add');
INSERT INTO "role_operation" VALUES (81, 'Guest', '/alert-mutes/del');
INSERT INTO "role_operation" VALUES (82, 'Guest', '/alert-subscribes');
INSERT INTO "role_operation" VALUES (83, 'Guest', '/alert-subscribes/add');
INSERT INTO "role_operation" VALUES (84, 'Guest', '/alert-subscribes/put');
INSERT INTO "role_operation" VALUES (85, 'Guest', '/alert-subscribes/del');
INSERT INTO "role_operation" VALUES (86, 'Guest', '/alert-cur-events');
INSERT INTO "role_operation" VALUES (87, 'Guest', '/alert-cur-events/del');
INSERT INTO "role_operation" VALUES (88, 'Guest', '/alert-his-events');
INSERT INTO "role_operation" VALUES (89, 'Guest', '/recording-rules');
INSERT INTO "role_operation" VALUES (90, 'Guest', '/recording-rules/add');
INSERT INTO "role_operation" VALUES (91, 'Guest', '/recording-rules/put');
INSERT INTO "role_operation" VALUES (92, 'Guest', '/recording-rules/del');
INSERT INTO "role_operation" VALUES (93, 'Guest', '/trace/dependencies');
INSERT INTO "role_operation" VALUES (94, 'Guest', '/targets');
INSERT INTO "role_operation" VALUES (95, 'Guest', '/targets/add');
INSERT INTO "role_operation" VALUES (96, 'Guest', '/targets/put');
INSERT INTO "role_operation" VALUES (97, 'Guest', '/targets/del');
INSERT INTO "role_operation" VALUES (98, 'Guest', '/job-tpls');
INSERT INTO "role_operation" VALUES (99, 'Guest', '/job-tpls/add');
INSERT INTO "role_operation" VALUES (100, 'Guest', '/job-tpls/put');
INSERT INTO "role_operation" VALUES (101, 'Guest', '/job-tpls/del');
INSERT INTO "role_operation" VALUES (102, 'Guest', '/job-tasks');
INSERT INTO "role_operation" VALUES (103, 'Guest', '/job-tasks/add');
INSERT INTO "role_operation" VALUES (104, 'Guest', '/job-tasks/put');
INSERT INTO "role_operation" VALUES (105, 'Guest', '/users');
INSERT INTO "role_operation" VALUES (106, 'Guest', '/user-groups');
INSERT INTO "role_operation" VALUES (107, 'Guest', '/user-groups/add');
INSERT INTO "role_operation" VALUES (108, 'Guest', '/user-groups/put');
INSERT INTO "role_operation" VALUES (109, 'Guest', '/user-groups/del');
INSERT INTO "role_operation" VALUES (110, 'Guest', '/busi-groups');
INSERT INTO "role_operation" VALUES (111, 'Guest', '/busi-groups/add');
INSERT INTO "role_operation" VALUES (112, 'Guest', '/busi-groups/put');
INSERT INTO "role_operation" VALUES (113, 'Guest', '/busi-groups/del');
INSERT INTO "role_operation" VALUES (114, 'Guest', '/help/servers');
INSERT INTO "role_operation" VALUES (115, 'Guest', '/help/source');
INSERT INTO "role_operation" VALUES (116, 'Guest', '/help/sso');
INSERT INTO "role_operation" VALUES (117, 'Guest', '/help/notification-tpls');
INSERT INTO "role_operation" VALUES (118, 'Guest', '/help/notification-settings');
INSERT INTO "role_operation" VALUES (119, 'Guest', '/help/migrate');

INSERT INTO "sso_config" VALUES (1, 'LDAP', '
Enable = false
Host = ''ldap.example.org''
Port = 389
BaseDn = ''dc=example,dc=org''
BindUser = ''cn=manager,dc=example,dc=org''
BindPass = ''*******''
AuthFilter = ''(&(uid=%s))''
CoverAttributes = true
TLS = false
StartTLS = true
DefaultRoles = [''Standard'']

[Attributes]
Nickname = ''cn''
Phone = ''mobile''
Email = ''mail''
');
INSERT INTO "sso_config" VALUES (2, 'CAS', '
Enable = false
SsoAddr = ''https://cas.example.com/cas/''
RedirectURL = ''http://127.0.0.1:18000/callback/cas''
DisplayName = ''CAS登录''
CoverAttributes = false
DefaultRoles = [''Standard'']

[Attributes]
Nickname = ''nickname''
Phone = ''phone_number''
Email = ''email''
');
INSERT INTO "sso_config" VALUES (3, 'OIDC', '
Enable = false
DisplayName = ''OIDC登录''
RedirectURL = ''http://n9e.com/callback''
SsoAddr = ''http://sso.example.org''
ClientId = ''''
ClientSecret = ''''
CoverAttributes = true
DefaultRoles = [''Standard'']

[Attributes]
Nickname = ''nickname''
Phone = ''phone_number''
Email = ''email''
');
INSERT INTO "sso_config" VALUES (4, 'OAuth2', '
Enable = false
DisplayName = ''OAuth2登录''
RedirectURL = ''http://127.0.0.1:18000/callback/oauth''
SsoAddr = ''https://sso.example.com/oauth2/authorize''
TokenAddr = ''https://sso.example.com/oauth2/token''
UserInfoAddr = ''https://api.example.com/api/v1/user/info''
TranTokenMethod = ''header''
ClientId = ''''
ClientSecret = ''''
CoverAttributes = true
DefaultRoles = [''Standard'']
UserinfoIsArray = false
UserinfoPrefix = ''data''
Scopes = [''profile'', ''email'', ''phone'']

[Attributes]
Username = ''username''
Nickname = ''nickname''
Phone = ''phone_number''
Email = ''email''
');

INSERT INTO "target" VALUES (1, 0, 'categraf01', '', '', 1689216077);
INSERT INTO "target" VALUES (2, 0, 'yuntu01', '', '', 1688708870);
INSERT INTO "target" VALUES (3, 0, 'localhost.localdomain', '', '', 1688603615);

INSERT INTO "user_group" VALUES (1, 'demo-root-group', '', 1688458902, 'root', 1688458902, 'root');

INSERT INTO "user_group_member" VALUES (1, 1, 1);

INSERT INTO "users" VALUES (1, 'root', '超管', '042c05fffc2f49ca29a76223f3a41e83', '', '', '', 'Admin', NULL, 0, 1688458902, 'system', 1688458902, 'system');
