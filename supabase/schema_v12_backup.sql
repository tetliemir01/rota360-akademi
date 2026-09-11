-- ROTA360 AKADEMİ V12
-- Supabase PostgreSQL şeması
create extension if not exists "pgcrypto";

create type public.user_role as enum ('coach','student');
create type public.task_type as enum ('konu','soru','tekrar','deneme','youtube');
create type public.task_priority as enum ('normal','onemli','kritik');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role public.user_role not null,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  school text,
  grade text,
  target_exam text,
  target_department text,
  weekly_question_target integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.coach_students (
  coach_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (coach_id, student_id)
);

create table public.programs (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  week_start date not null,
  weekly_goal text,
  daily_question_target integer not null default 0,
  coach_note text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id) on delete cascade,
  task_date date not null,
  type public.task_type not null,
  subject text not null,
  topic text,
  question_count integer not null default 0,
  duration_minutes integer not null default 0,
  priority public.task_priority not null default 'normal',
  student_note text,
  is_completed boolean not null default false,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.video_assignments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null unique references public.tasks(id) on delete cascade,
  youtube_url text not null,
  title text not null,
  duration_minutes integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.exam_results (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  exam_type text not null check (exam_type in ('TYT','AYT')),
  exam_name text,
  exam_date date not null,
  turkish_correct integer not null default 0,
  turkish_wrong integer not null default 0,
  turkish_blank integer not null default 0,
  math_correct integer not null default 0,
  math_wrong integer not null default 0,
  math_blank integer not null default 0,
  science_correct integer not null default 0,
  science_wrong integer not null default 0,
  science_blank integer not null default 0,
  social_correct integer not null default 0,
  social_wrong integer not null default 0,
  social_blank integer not null default 0,
  total_net numeric(6,2) generated always as (
    (turkish_correct - turkish_wrong / 4.0) +
    (math_correct - math_wrong / 4.0) +
    (science_correct - science_wrong / 4.0) +
    (social_correct - social_wrong / 4.0)
  ) stored,
  created_at timestamptz not null default now()
);

create table public.topic_analysis (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  subject text not null,
  topic text not null,
  wrong_count integer not null default 0,
  priority text not null default 'normal',
  recommendation text,
  updated_at timestamptz not null default now(),
  unique(student_id, subject, topic)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_tasks_program_date on public.tasks(program_id, task_date);
create index idx_exams_student_date on public.exam_results(student_id, exam_date desc);
create index idx_notifications_profile on public.notifications(profile_id, created_at desc);

-- Auth kullanıcısı oluşturulduğunda profile satırı için güvenli yardımcı fonksiyon.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name','Yeni Kullanıcı'),
    coalesce((new.raw_user_meta_data->>'role')::public.user_role,'student')
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.coach_students enable row level security;
alter table public.programs enable row level security;
alter table public.tasks enable row level security;
alter table public.video_assignments enable row level security;
alter table public.exam_results enable row level security;
alter table public.topic_analysis enable row level security;
alter table public.notifications enable row level security;

create or replace function public.is_coach_of_student(p_student uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists (
    select 1 from public.coach_students cs
    where cs.coach_id = auth.uid() and cs.student_id = p_student
  );
$$;

create or replace function public.student_id_of_user()
returns uuid language sql stable security definer set search_path=public as $$
  select id from public.students where profile_id = auth.uid() limit 1;
$$;

create policy profiles_self on public.profiles
for select using (id=auth.uid());

create policy students_self_or_coach on public.students
for select using (
  profile_id=auth.uid() or public.is_coach_of_student(id)
);

create policy coach_manage_links on public.coach_students
for all using (coach_id=auth.uid()) with check (coach_id=auth.uid());

create policy programs_student_or_coach on public.programs
for select using (
  student_id=public.student_id_of_user() or public.is_coach_of_student(student_id)
);
create policy programs_coach_insert on public.programs
for insert with check (
  created_by=auth.uid() and public.is_coach_of_student(student_id)
);
create policy programs_coach_update on public.programs
for update using (created_by=auth.uid() and public.is_coach_of_student(student_id));

create policy tasks_student_or_coach on public.tasks
for select using (
  exists (
    select 1 from public.programs p
    where p.id=program_id
    and (p.student_id=public.student_id_of_user() or public.is_coach_of_student(p.student_id))
  )
);
create policy tasks_student_update on public.tasks
for update using (
  exists (
    select 1 from public.programs p
    where p.id=program_id and p.student_id=public.student_id_of_user()
  )
) with check (true);
create policy tasks_coach_insert on public.tasks
for insert with check (
  exists (
    select 1 from public.programs p
    where p.id=program_id and public.is_coach_of_student(p.student_id)
  )
);

create policy videos_visible on public.video_assignments
for select using (
  exists (
    select 1 from public.tasks t
    join public.programs p on p.id=t.program_id
    where t.id=task_id
    and (p.student_id=public.student_id_of_user() or public.is_coach_of_student(p.student_id))
  )
);
create policy videos_coach_insert on public.video_assignments
for insert with check (
  exists (
    select 1 from public.tasks t
    join public.programs p on p.id=t.program_id
    where t.id=task_id and public.is_coach_of_student(p.student_id)
  )
);

create policy exams_student_or_coach on public.exam_results
for select using (student_id=public.student_id_of_user() or public.is_coach_of_student(student_id));
create policy exams_student_insert on public.exam_results
for insert with check (student_id=public.student_id_of_user());

create policy topic_student_or_coach on public.topic_analysis
for select using (student_id=public.student_id_of_user() or public.is_coach_of_student(student_id));

create policy notifications_self on public.notifications
for select using (profile_id=auth.uid());
create policy notifications_update_self on public.notifications
for update using (profile_id=auth.uid());
