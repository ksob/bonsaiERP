# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class ApplicationController < ActionController::Base
  layout lambda{ |c| 
    if (c.request.xhr? or params[:xhr])
      false 
    elsif params[:print].present?
      "print"
    else
     "application" 
    end
  }

  include Controllers::Authentication
  helper_method Controllers::Authentication.helpers
  #rescue_from Exception, :with => :render_error

  include Controllers::Authorization
  helper_method Controllers::OrganisationHelpers.organisation_helper_methods

  protect_from_forgery

  ########################################
  # Callbacks
  before_filter :set_user_session, :if => :user_signed_in?
  before_filter :set_page, :set_tenant, :check_authorization!
  before_filter :set_organisation_session

  def render_error(exception) 
    if notifier = Rails.application.config.middleware.detect { |x| x.klass == ExceptionNotifier } 
      env['exception_notifier.options'] = notifier.args.first || {} 
      logger.error exception.inspect 
      logger.error exception.backtrace.join("\n") 
      ExceptionNotifier::Notifier.exception_notification(env, exception).deliver 
      env['exception_notifier.delivered'] = true 
    end
  end

  #Put this in applictation_controller.rb
  #before_filter :log_ram # or use after_filter
  #def log_ram
  #  logger.warn 'RAM USAGE: ' + `pmap #{Process.pid} | tail -1`[10,40].strip
  #end

  # Adds an error with format to display
  # @param ActiveRecord::Base (model)
  def add_flash_error(model)
    flash[:error] = I18n.t("flash.error") if flash[:error].nil?
      
    unless model.errors.base.empty?
      flash[:error] << "<ul>"
      model.errors[:base].map{|e| flash[:error] << %Q(<li>#{e}</li>) }
      flash[:error] << "<ul>"
    end
  end

  # especial redirect for ajax requests
  def redirect_ajax(klass, options = {})
    url = options[:url] || klass
    if request.xhr?
      if request.delete?
        render :json => klass.to_json(:methods => [ :destroyed?, :errors ])
      else
        render :json => klass
      end
    else
      if request.delete?
        set_redirect_options(klass, options) 
        url = "/#{klass.class.to_s.downcase.pluralize}" unless url.is_a?(String)
      end

      redirect_to url
    end
  end

  # Add some helper methods to the controllers
  def help
    Helper.instance
  end

  def current_organisation
    @organisation ||= Organisation.find_by_tenant(current_tenant)
  end
  helper_method :current_organisation

protected
  # Creates the flash messages when an item is deleted
  def set_redirect_options(klass, options)
    if klass.destroyed?
      case
      when (options[:notice].blank? and flash[:notice].blank?)
        flash[:notice] = "Se ha eliminado el registro correctamente."
      when (options[:notice] and flash[:notice].blank?)
        flash[:notice] = options[:notice]
      end
    else
      if flash[:error].blank? and klass.errors.any?
        txt = options[:error] ? options[:error] : "No se pudo borrar el registro: #{klass.errors[:base].join(", ")}." 
        flash[:error] = txt
      elsif flash[:error].blank?
        txt = options[:error] ? options[:error] : "No se pudo borrar el registro."
        flash[:error] = txt
      end
    end
  end

  def currency
    current_organisation.currency
  end
  helper_method :currency

private
  def set_page
    @page = params[:page] || 1
  end

  def current_tenant
    request.subdomain
  end

  def destroy_organisation_session!
    session[:organisation] = {}
    OrganisationSession.destroy
  end

  # Uses the helper methods from devise to made them available in the models
  def set_user_session
    UserSession.user = current_user
  end

   # Checks if is set the organisation session
  def organisation?
    current_organisation.present?
  end
  helper_method :organisation?

  # Checks if the currency has been set
  def check_currency_set
    org = current_organisation
    unless CurrencyRate.current?(org)
      flash[:warning] = "Debe actualizar los tipos de cambio."
      redirect_to new_currency_rate_path
    end
  end

  def set_tenant
    PgTools.change_tenant current_tenant
  end

  def set_organisation_session
    if current_organisation
      OrganisationSession.organisation = current_organisation
    end
  end

  def login_verification
    @valid_verification ||= Controllers::LoginVerification.new(self)
  end
end
