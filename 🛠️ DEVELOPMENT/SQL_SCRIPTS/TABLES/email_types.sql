create table
  public.email_types (
    id smallserial not null,
    type character varying(50) not null,
    description text null,
    created_at timestamp with time zone null default timezone ('utc'::text, now()),
    constraint email_types_pkey primary key (id),
    constraint email_types_type_key unique (
      type
    )
  ) tablespace pg_default;