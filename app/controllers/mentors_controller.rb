class MentorsController < ApplicationController

  def index
    not check_access(true, true) and return
    @mentors = Mentor.all
    render
  end

  def new
    not check_access(true, true) and return
    @mentor = Mentor.new
    render locals: {
             user: User.new,
             users: User.all
           }
  end

  def create
    not check_access(true, true) and return
    user = User.new(get_user_params)
    flash = {}
    if not user.save
      render_new_template_with_err(user)
    end
    @mentor = Mentor.new(user_id: user.id)
    if @mentor.save
      flash[:success] = 'The mentor is successfully created'
      redirect_to mentors_path, flash: flash
    else
      render_new_template_with_err(user)
    end
  end

  def use_existing
    not check_access(true, true) and return
    user = User.find(params[:mentor][:user_id])
    if not user
      render_new_template_with_err(user) and return
    end
    @mentor = Mentor.new(user_id: user.id)
    if @mentor.save
      flash = {}
      flash[:success] = 'The mentor is successfully created'
      redirect_to mentors_path, flash: flash
    else
      render_new_template_with_err(user)
    end
  end

  def show
    not check_access(true, false) and return
    @mentor = Mentor.find(params[:id])
    milestones, teams_submissions, own_evaluations = get_data_for_mentor
    render locals: {
             milestones: milestones,
             teams_submissions: teams_submissions,
             own_evaluations: own_evaluations
           }
  end

  def edit
    not check_access(true, true) and return
    @mentor = Mentor.find(params[:id])
    render
  end

  def update
    not check_access(true, true) and return
    @mentor = Mentor.find(params[:id])
    user = @mentor.user
    if user.update(get_user_params)
      if admin?
        redirect_to mentors_path
      else
        redirect_to @mentor
      end
    else
      render template: 'edit'
    end
  end

  def destroy
    not check_access(true, true) and return
    @mentor = Mentor.find(params[:id])
    @mentor.destroy
    redirect_to mentors_path
  end

  def get_page_title
    @page_title = @page_title || 'Mentors | Orbital'
    super
  end

  private
    def get_user_params
      user_param = params.require(:user).permit(:user_name, :email, :uid, :provider)
    end

    def render_new_template_with_err(user)
      render template: 'mentors/new', locals: {
                               users: User.all,
                               user: user
                             }
    end

    def get_data_for_mentor
      milestones = Milestone.all
      teams_submissions = {}
      own_evaluations = {}
      milestones.each do |milestone|
        teams_submissions[milestone.id] = {}
        @mentor.teams.each do |team|
          teams_submissions[milestone.id][team.id] = Submission.find_by(milestone_id: milestone.id,
                                                                        team_id: team.id)
        end
      end
      return milestones, teams_submissions, own_evaluations
    end
end
