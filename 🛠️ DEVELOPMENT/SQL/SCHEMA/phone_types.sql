create table
  public.phone_types (
    id smallserial not null,
    type character varying(50) not null,
    description text null,
    created_at timestamp with time zone null default timezone ('utc'::text, now()),
    constraint phone_types_pkey primary key (id),
    constraint phone_types_type_key unique (
      type
    )
  ) tablespace pg_default;