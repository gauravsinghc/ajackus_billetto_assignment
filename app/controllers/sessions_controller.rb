class SessionsController < ApplicationController
  def destroy
    session_id = clerk.session&.dig('sid')

    if session_id.present?
      begin
        Clerk::SDK.new.sessions.revoke(session_id: session_id)
      rescue => e
        Rails.logger.error "Failed to revoke Clerk session: #{e.message}"
      end
    end

    cookies.delete(:__session)
    cookies.delete(:__client_uat)

    cookies.delete(:test_user_id) if Rails.env.test?
    
    redirect_to root_path
  end
end