class TasksController < ApplicationController
  before_action :set_post
  before_action :set_task, only: %i[ show edit update destroy ]

  # GET /posts/:post_id/tasks
  def index
    @tasks = @post.tasks
  end

  # GET /posts/:post_id/tasks/1
  def show
  end

  # GET /posts/:post_id/tasks/new
  def new
    @task = @post.tasks.build
  end

  # GET /posts/:post_id/tasks/1/edit
  def edit
  end

  # POST /posts/:post_id/tasks
  def create
    @task = @post.tasks.build(task_params)
    if @task.save
      redirect_to post_task_path(@post, @task), notice: 'Task was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /posts/:post_id/tasks/1
  def update
    if @task.update(task_params)
      redirect_to post_task_path(@post, @task), notice: 'Task was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /posts/:post_id/tasks/1
  def destroy
    @task.destroy
    redirect_to post_tasks_path(@post), notice: 'Task was successfully destroyed.'
  end

  private
    def set_post
      @post = Post.find(params[:post_id])
    end

    def set_task
      @task = @post.tasks.find(params[:id])
    end

    def task_params
      params.require(:task).permit(:name, :description)
    end
end