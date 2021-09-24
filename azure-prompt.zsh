setopt prompt_subst
autoload -U add-zsh-hook

function() {
    local subscription_id separator binary

    # Specify the separator between Tenant and Subscription
    zstyle -s ':zsh-subscription-prompt:' separator separator
    if [[ -z "$separator" ]]; then
        zstyle ':zsh-subscription-prompt:' separator '/'
    fi

    # Display the current subscription if `subscription` is true
    zstyle -s ':zsh-subscription-prompt:' subscription_id subscription_id
    if [[ -z "$subscription_id" ]]; then
        zstyle ':zsh-subscription-prompt:' subscription_id true
    fi

    # Specify the binary to get the information
    zstyle -s ':zsh-subscription-binary:' binary binary
    if [[ -z "$binary" ]]; then
        zstyle ':zsh-subscription-prompt:' binary "jq"
    fi
}

add-zsh-hook precmd _zsh_subscription_prompt_precmd
function _zsh_subscription_prompt_precmd() {
    local updated_at now tenant subscription_id subscription_name separator modified_time_fmt binary

    #Check if binary is present
    zstyle -s ':zsh-subscription-prompt:' binary binary
    if ! command -v "$binary" >/dev/null; then
      ZSH_SUBSCRIPTION_PROMPT="${binary} command not found"
      return 1
    fi

    zstyle -s ':zsh-subscription-prompt:' modified_time_fmt modified_time_fmt
    if [[ -z "$modified_time_fmt" ]]; then
      # Check the stat command because it has a different syntax between GNU coreutils and FreeBSD.
      if stat --help >/dev/null 2>&1; then
          modified_time_fmt='-c%y' # GNU coreutils
      else
          modified_time_fmt='-f%m' # FreeBSD
      fi
      zstyle ':zsh-subscription-prompt:' modified_time_fmt $modified_time_fmt
    fi
        
    zstyle ':zsh-subscription-prompt:' updated_at "$now"

    azure_config="$HOME/.azure/azureProfile.json"
    if [ ! -f $azure_config ]; then
        return 1
    fi

    subscription_name=`$binary -r '.subscriptions[] | select(.isDefault == true) | .name' $azure_config`
    tenant=`$binary -r '.subscriptions[] | select(.isDefault == true) | .tenantId' $azure_config`
    # Specify the entry before prompt (default empty)
    zstyle -s ':zsh-subscription-prompt:' preprompt preprompt
    # Specify the entry after prompt (default empty)
    zstyle -s ':zsh-subscription-prompt:' postprompt postprompt

    # Set environment variable without tenant
    zstyle -s ':zsh-kubectl-prompt:' tenant tenant
    if [[ "$tenant" == true ]]; then
        ZSH_SUBSCRIPTION_PROMPT="${preprompt}${tenant}${separator}${subscription_name}${postprompt}"
        return 0
    fi

    zstyle -s ':zsh-subscription-prompt:' separator separator
    ZSH_SUBSCRIPTION_PROMPT="${preprompt}${subscription_name}${postprompt}"

    return 0
}