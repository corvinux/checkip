# config valid for current version and patch releases of Capistrano
lock "~> 3.17.0"

set :application, 'checkip'
set :repo_url, 'git@github.com:checkip/checkip.git'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, 'main'

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, "/var/www/my_app_name"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml"

# Default value for linked_dirs is []
append :linked_dirs, '.bundle', 'mmdb', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# Capistrano::Maintenance
set :maintenance_template_path, File.expand_path('../public/maintenance.html', __dir__)

# Fix for Capistrano::FileNotFound: Rails assets manifest file not found.
Rake::Task['deploy:assets:backup_manifest'].clear_actions

after 'deploy:finished',  'systemd:puma:restart'

namespace :systemd do
  namespace :puma do
    desc 'Puma.service restart (including puma.socket)'
    task :restart do
      on roles(:app) do
        systemctl_test = test(:systemctl, 'is-active puma.socket --quiet')
        systemctl_capture = capture(:systemctl,
                                    'is-active puma.socket',
                                    raise_on_non_zero_exit: false)

        if systemctl_test
          execute 'sudo systemctl restart puma.socket puma.service'
        elsif systemctl_capture == 'inactive'
          execute 'sudo systemctl enable puma.socket puma.service --now'
        else
          error "puma.socket - #{systemctl_capture}"
        end
      end
    end
  end
end
