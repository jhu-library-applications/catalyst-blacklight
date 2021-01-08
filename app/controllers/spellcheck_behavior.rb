require 'yboss_spell'

# Mixed into a controller, to give us spellcheck behavior
#
# TODO: Use a celluloid background thread, and an around_filter, to do this
# request without slowing down response time?
module SpellcheckBehavior

  protected

  # Wire up with `before_filter :spellcheck, :only => [:action]`
  # to spellcheck and put a suggestion, if any in @spell_suggestion.
  #
  # Assumes query is in params[:q].
  #
  # @spell_suggestion may be falsae (rather than nil) in case of spell service
  # error.
  #
  # Only spell checks if #should_spell_check?
  def spellcheck
    if should_spell_check?
      @yboss_spell ||= YBossSpell.new
      @spell_suggestion = @yboss_spell.get_suggestion(params[:q])
    end
  end

  # WE HAVE DISABLED SPELLCHECK jun 15 2015
  # by making this always return false
  #
  # Left the code in place in case we want to bring it back, since it had some
  # tricky things. 
  #
  #
  #
  # We don't want to spellcheck on every query, as we have to pay for them.
  # Not on pagination or facet drilldown etc. We check params[:page], and
  # other links need to set "should_spellcheck=0" to suppress spellchecking.
  #
  # also check user-agents for bots?
  #
  # only spell suggest for ascii_only? queries, Yahoo performs too poorly
  # on non-ascii including diacritics and non-Latin script.
  #
  # Only spell check for HTML responses, not atom responses. Don't spellcheck
  # for CQL searches either. 
  def should_spell_check?
    # FORCE DISABLE Jun 15 2015
    return false

    should = 
    params[:q].present? && params[:q].ascii_only? && (params[:page].nil? || params[:page] == "1") &&
      (! probably_bot?) && (params[:suppress_spellcheck] != "1") && params[:search_field] != "cql" && 
      # Pretty hacky way to try and make sure we're going to render html,not atom or
      # something else. not entirely robust, but best rails gives us. 
      (params[:format].blank? || params[:format] == "html")

    return should
  end

  @@probably_bot_regexp = /(Baidu|Googlebot|msnbot|Yandex|Sosospider|Sosoimagespider|Exabot|Sogou|\+http\:)/i
  # We don't want to spend money on spellcheck for bots. But we have no
  # great way to know if a request is from a bot, we just hard-code
  # these 'top ten bots' http://www.incapsula.com/the-incapsula-blog/item/393-know-your-top-10-bots
  #
  # Also any user-agent including the string "+http:", fellow dev suggested was a good
  # way to catch bots. 
  #
  # Also EMPTY user agent, we'll consider probably a bot. 
  def probably_bot?
    request.env["HTTP_USER_AGENT"] =~ @@probably_bot_regexp  || request.env["HTTP_USER_AGENT"].blank?
  end

end
