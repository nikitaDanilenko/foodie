create table session
(
    id      uuid not null,
    user_id uuid not null
);

alter table session
    add constraint session_pk primary key (id),
    add constraint session_user_id_fk foreign key (user_id) references "user"(id) on delete cascade;
