module ApplicationHelper
  def sidebar_active_class(path, active_check: nil)
    is_active = if active_check
      instance_exec(&active_check)
    else
      request.path == path
    end

    if is_active
      "bg-indigo-600/20 text-indigo-300 border border-indigo-500/20"
    else
      "text-zinc-400 hover:text-zinc-100 hover:bg-zinc-800/60"
    end
  end
end
