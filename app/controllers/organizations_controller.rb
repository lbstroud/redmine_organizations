class OrganizationsController < ApplicationController
  unloadable
  
  layout 'admin'
  
  def index
    @organizations = Organization.all(:order => 'lft')
  end
  
  def show
    @organization = Organization.find(params[:id])
    #@custom_values = @user.custom_values
    @custom_values = []
    
    @memberships = @organization.memberships.all(:include => :project,
                                                 :conditions => Project.visible_by(User.current))
    
    @users = @organization.users
    
    events = []
    #@users.each do |user|
    #  events << Redmine::Activity::Fetcher.new(User.current, :author => user).events(nil, nil, :limit => 10)
    #end
    #@events_by_day = events.group_by(&:event_date) <<undefined method 'event_date' for Array
    @events_by_day = []
    
    render :layout => 'base'

  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def new
    @organization = Organization.new
  end
  
  def edit
    @organization = Organization.find(params[:id])
    @roles = Role.find_all_givable
    @projects = Project.active.all(:order => 'lft')
  end
  
  def create
    @organization = Organization.new(params[:organization])
    if @organization.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to(@organization)
    else
     render :action => "new"
    end
  end
  
  def update
    @organization = Organization.find(params[:id])
    if @organization.update_attributes(params[:organization])
      flash[:notice] = l(:notice_successful_update)
      redirect_to(@organization)
    else
      render :action => "edit"
    end
  end
  
  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to(organizations_url)
  end
  
  def add_users
    @organization = Organization.find(params[:id])
    users = User.find_all_by_id(params[:user_ids])
    @organization.users << users if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'users' }
      format.js { 
        render(:update) {|page| 
          page.replace_html "tab-content-users", :partial => 'organizations/users'
          users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
        }
      }
    end
  end
  
  def remove_user
    @organization = Organization.find(params[:id])
    @organization.users.delete(User.find(params[:user_id])) if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'organizations', :action => 'edit', :id => @organization, :tab => 'users' }
      format.js { render(:update) {|page| page.replace_html "tab-content-users", :partial => 'organizations/users'} }
    end
  end
  
  def autocomplete_for_user
    @organization = Organization.find(params[:id])
    @users = User.active.like(params[:q]).find(:all, :limit => 100) - @organization.users
    render :layout => false
  end
end
