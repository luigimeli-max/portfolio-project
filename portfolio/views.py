"""
Portfolio Views

This module contains all views for the portfolio website,
including homepage, project detail, and contact form handling.
"""

from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.http import require_POST
from django.core.mail import send_mail
from django.conf import settings
from django.core.paginator import Paginator

from .models import (
    Project, 
    Testimonial, 
    Skill, 
    TimelineEvent, 
    SiteSettings,
    ContactMessage
)
from .forms import ContactForm


def index(request):
    """
    Homepage view.
    
    Renders the main portfolio page with all sections:
    - Hero
    - About/Intro
    - Timeline
    - Projects showcase
    - Testimonials
    - Skills matrix
    - Stats
    - Work process
    - Contact CTA
    """
    # Get site settings
    site_settings = SiteSettings.get_settings()
    
    # Get featured project for hero showcase
    featured_project = Project.objects.filter(
        featured=True, 
        is_visible=True
    ).first()
    
    # Get all visible projects
    projects = Project.objects.filter(is_visible=True).order_by('order', '-created_at')
    
    # Get unique tech stack for filters
    all_tech = set()
    for project in projects:
        for tech in project.tech_stack_list:
            all_tech.add(tech)
    tech_filters = sorted(list(all_tech))
    
    # Get testimonials
    testimonials = Testimonial.objects.filter(is_visible=True).order_by('order')
    
    # Get skills grouped by category
    skills = Skill.objects.filter(is_visible=True).order_by('category', 'order')
    skills_by_category = {}
    for skill in skills:
        category = skill.get_category_display()
        if category not in skills_by_category:
            skills_by_category[category] = []
        skills_by_category[category].append(skill)
    
    # Get timeline events
    timeline_events = TimelineEvent.objects.filter(is_visible=True).order_by('order')
    
    # Contact form
    contact_form = ContactForm()
    
    context = {
        'site_settings': site_settings,
        'featured_project': featured_project,
        'projects': projects,
        'tech_filters': tech_filters,
        'testimonials': testimonials,
        'skills_by_category': skills_by_category,
        'timeline_events': timeline_events,
        'contact_form': contact_form,
    }
    
    return render(request, 'portfolio/index.html', context)


def project_detail(request, slug):
    """
    Project detail view.
    
    Renders a detailed case study page for a single project,
    including full description, gallery, and related projects.
    """
    project = get_object_or_404(Project, slug=slug, is_visible=True)
    
    # Get related projects (same category, excluding current)
    related_projects = Project.objects.filter(
        category=project.category,
        is_visible=True
    ).exclude(pk=project.pk).order_by('order')[:3]
    
    # Get site settings for navigation
    site_settings = SiteSettings.get_settings()
    
    context = {
        'project': project,
        'related_projects': related_projects,
        'site_settings': site_settings,
    }
    
    return render(request, 'portfolio/project_detail.html', context)


def projects_list(request):
    """
    All projects list view with filtering and pagination.
    """
    projects = Project.objects.filter(is_visible=True).order_by('order', '-created_at')
    
    # Filter by category
    category = request.GET.get('category')
    if category:
        projects = projects.filter(category=category)
    
    # Filter by tech
    tech = request.GET.get('tech')
    if tech:
        projects = projects.filter(tech_stack__contains=tech)
    
    # Pagination
    paginator = Paginator(projects, 9)  # 9 projects per page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    # Get unique tech stack for filters
    all_projects = Project.objects.filter(is_visible=True)
    all_tech = set()
    for project in all_projects:
        for t in project.tech_stack_list:
            all_tech.add(t)
    tech_filters = sorted(list(all_tech))
    
    site_settings = SiteSettings.get_settings()
    
    context = {
        'projects': page_obj,
        'tech_filters': tech_filters,
        'current_category': category,
        'current_tech': tech,
        'site_settings': site_settings,
    }
    
    return render(request, 'portfolio/projects_list.html', context)


@require_POST
def contact_submit(request):
    """
    Handle contact form submission.
    
    Validates form, saves message to database, and sends email notification.
    Returns JSON response for AJAX handling.
    """
    form = ContactForm(request.POST)
    
    if form.is_valid():
        # Save to database
        message = ContactMessage.objects.create(
            name=form.cleaned_data['name'],
            email=form.cleaned_data['email'],
            subject=form.cleaned_data.get('subject', ''),
            message=form.cleaned_data['message']
        )
        
        # Send email notification
        try:
            subject = f"[Portfolio] Nuovo messaggio da {form.cleaned_data['name']}"
            email_message = f"""
Nuovo messaggio dal portfolio:

Nome: {form.cleaned_data['name']}
Email: {form.cleaned_data['email']}
Oggetto: {form.cleaned_data.get('subject', 'Nessun oggetto')}

Messaggio:
{form.cleaned_data['message']}
            """
            
            send_mail(
                subject,
                email_message,
                settings.DEFAULT_FROM_EMAIL,
                [settings.CONTACT_EMAIL],
                fail_silently=True,
            )
        except Exception as e:
            # Log error but don't fail the request
            pass
        
        return JsonResponse({
            'success': True,
            'message': 'Grazie per il tuo messaggio! Ti risponderò presto.'
        })
    else:
        return JsonResponse({
            'success': False,
            'errors': form.errors
        }, status=400)


def custom_404(request, exception):
    """Custom 404 error page."""
    return render(request, 'portfolio/404.html', status=404)


def custom_500(request):
    """Custom 500 error page."""
    return render(request, 'portfolio/500.html', status=500)


# API Views (for potential AJAX usage)
def api_projects(request):
    """
    API endpoint to get projects as JSON.
    Useful for dynamic filtering without page reload.
    """
    projects = Project.objects.filter(is_visible=True).order_by('order')
    
    # Filter by tech if provided
    tech = request.GET.get('tech')
    if tech:
        projects = projects.filter(tech_stack__contains=tech)
    
    # Filter by category
    category = request.GET.get('category')
    if category:
        projects = projects.filter(category=category)
    
    data = []
    for project in projects:
        data.append({
            'id': project.id,
            'title': project.title,
            'slug': project.slug,
            'description': project.description,
            'thumbnail': project.image_thumbnail.url if project.image_thumbnail else '',
            'tech_stack': project.tech_stack_list,
            'category': project.category,
            'external_url': project.external_url,
            'detail_url': project.get_absolute_url(),
            'featured': project.featured,
        })
    
    return JsonResponse({'projects': data})
