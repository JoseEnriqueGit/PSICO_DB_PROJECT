create table
  public.job_statuses (
    id smallserial not null,
    status character varying(50) not null,
    description text null,
    created_at timestamp with time zone null default timezone ('utc'::text, now()),
    constraint job_statuses_pkey primary key (id),
    constraint job_statuses_status_key unique (status)
  ) tablespace pg_default;