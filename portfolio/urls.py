"""
Portfolio URL Configuration

URL patterns for the portfolio app.
"""

from django.urls import path
from . import views

app_name = 'portfolio'

urlpatterns = [
    # Main pages
    path('', views.index, name='index'),
    path('projects/', views.projects_list, name='projects_list'),
    path('project/<slug:slug>/', views.project_detail, name='project_detail'),
    
    # Contact form
    path('contact/submit/', views.contact_submit, name='contact_submit'),
    
    # API endpoints
    path('api/projects/', views.api_projects, name='api_projects'),
]
