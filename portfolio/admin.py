"""
Portfolio Admin Configuration

Customized admin panel for managing portfolio content.
Includes image previews, drag-drop ordering, and custom filters.
"""

from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe

from .models import (
    Project,
    Testimonial,
    Skill,
    TimelineEvent,
    SiteSettings,
    ContactMessage
)


# Custom Admin Site Configuration
admin.site.site_header = 'Portfolio Admin'
admin.site.site_title = 'Portfolio Admin'
admin.site.index_title = 'Gestione Contenuti'


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    """
    Admin configuration for Project model.
    Features: image preview, tech stack display, ordering.
    """
    
    list_display = [
        'thumbnail_preview',
        'title',
        'category',
        'tech_tags',
        'featured_badge',
        'featured',
        'is_visible',
        'order',
        'created_at'
    ]
    list_display_links = ['thumbnail_preview', 'title']
    list_editable = ['order', 'is_visible', 'featured']
    list_filter = ['category', 'featured', 'is_visible', 'created_at']
    search_fields = ['title', 'description', 'tech_stack']
    prepopulated_fields = {'slug': ('title',)}
    ordering = ['order', '-created_at']
    
    fieldsets = (
        ('Informazioni Base', {
            'fields': ('title', 'slug', 'description', 'category')
        }),
        ('Contenuto Dettagliato', {
            'fields': ('long_description', 'challenge', 'solution', 'results'),
            'classes': ('collapse',)
        }),
        ('Immagini', {
            'fields': ('image_thumbnail', 'image_hero', 'gallery'),
            'description': 'Carica immagini ottimizzate (WebP consigliato)'
        }),
        ('Tecnologie & Link', {
            'fields': ('tech_stack', 'external_url', 'github_url')
        }),
        ('Opzioni Visualizzazione', {
            'fields': ('featured', 'is_visible', 'order')
        }),
    )
    
    def thumbnail_preview(self, obj):
        """Display thumbnail preview in list view."""
        if obj.image_thumbnail:
            return format_html(
                '<img src="{}" style="width: 80px; height: 50px; '
                'object-fit: cover; border-radius: 4px; '
                'border: 1px solid #333;"/>',
                obj.image_thumbnail.url
            )
        return format_html(
            '<div style="width: 80px; height: 50px; background: #1a1a1a; '
            'border-radius: 4px; display: flex; align-items: center; '
            'justify-content: center; color: #666;">No img</div>'
        )
    thumbnail_preview.short_description = 'Preview'
    
    def tech_tags(self, obj):
        """Display tech stack as colored tags."""
        if not obj.tech_stack_list:
            return '-'
        tags = ''.join([
            f'<span style="background: #00d9ff22; color: #00d9ff; '
            f'padding: 2px 8px; border-radius: 4px; margin-right: 4px; '
            f'font-size: 11px; display: inline-block; margin-bottom: 2px;">'
            f'{tech}</span>'
            for tech in obj.tech_stack_list[:4]
        ])
        if len(obj.tech_stack_list) > 4:
            tags += f'<span style="color: #666;">+{len(obj.tech_stack_list) - 4}</span>'
        return mark_safe(tags)
    tech_tags.short_description = 'Tech Stack'
    
    def featured_badge(self, obj):
        """Display featured status as badge."""
        if obj.featured:
            return format_html(
                '<span style="background: #00d9ff; color: #000; '
                'padding: 2px 8px; border-radius: 4px; font-weight: bold; '
                'font-size: 10px;">⭐ FEATURED</span>'
            )
        return '-'
    featured_badge.short_description = 'Featured'


@admin.register(Testimonial)
class TestimonialAdmin(admin.ModelAdmin):
    """Admin configuration for Testimonial model."""
    
    list_display = [
        'photo_preview',
        'name',
        'role',
        'project',
        'is_visible',
        'order'
    ]
    list_display_links = ['photo_preview', 'name']
    list_editable = ['order', 'is_visible']
    list_filter = ['is_visible', 'project']
    search_fields = ['name', 'role', 'quote']
    ordering = ['order']
    
    def photo_preview(self, obj):
        """Display photo preview in list view."""
        if obj.photo:
            return format_html(
                '<img src="{}" style="width: 40px; height: 40px; '
                'object-fit: cover; border-radius: 50%;"/>',
                obj.photo.url
            )
        return format_html(
            '<div style="width: 40px; height: 40px; background: #1a1a1a; '
            'border-radius: 50%; display: flex; align-items: center; '
            'justify-content: center; color: #666; font-size: 16px;">👤</div>'
        )
    photo_preview.short_description = 'Foto'


@admin.register(Skill)
class SkillAdmin(admin.ModelAdmin):
    """Admin configuration for Skill model."""
    
    list_display = [
        'name',
        'category',
        'proficiency_bar',
        'years_experience',
        'is_visible',
        'order'
    ]
    list_editable = ['order', 'is_visible']
    list_filter = ['category', 'is_visible']
    search_fields = ['name']
    ordering = ['category', 'order']
    filter_horizontal = ['related_projects']
    
    def proficiency_bar(self, obj):
        """Display proficiency as progress bar."""
        color = '#00d9ff' if obj.proficiency >= 70 else '#00b8cc'
        if obj.proficiency < 50:
            color = '#ff6b6b'
        return format_html(
            '<div style="width: 100px; height: 10px; background: #1a1a1a; '
            'border-radius: 5px; overflow: hidden;">'
            '<div style="width: {}%; height: 100%; background: {};"></div>'
            '</div>'
            '<span style="font-size: 11px; color: #888;">{}%</span>',
            obj.proficiency, color, obj.proficiency
        )
    proficiency_bar.short_description = 'Livello'


@admin.register(TimelineEvent)
class TimelineEventAdmin(admin.ModelAdmin):
    """Admin configuration for TimelineEvent model."""
    
    list_display = [
        'color_dot',
        'year',
        'title',
        'is_visible',
        'order'
    ]
    list_display_links = ['color_dot', 'year', 'title']
    list_editable = ['order', 'is_visible']
    list_filter = ['is_visible']
    ordering = ['order']
    
    def color_dot(self, obj):
        """Display timeline color dot."""
        return format_html(
            '<span style="display: inline-block; width: 12px; height: 12px; '
            'border-radius: 50%; background: {}; box-shadow: 0 0 8px {}40;"></span>',
            obj.color, obj.color
        )
    color_dot.short_description = ''


@admin.register(SiteSettings)
class SiteSettingsAdmin(admin.ModelAdmin):
    """
    Admin configuration for SiteSettings.
    Singleton model - only one instance allowed.
    """
    
    fieldsets = (
        ('Informazioni Base', {
            'fields': ('site_name', 'tagline', 'profile_image')
        }),
        ('Hero Section', {
            'fields': ('hero_title', 'hero_subtitle')
        }),
        ('Chi Sono', {
            'fields': ('about_text',)
        }),
        ('Contatti', {
            'fields': ('email', 'phone', 'location')
        }),
        ('Social Media', {
            'fields': ('github_url', 'linkedin_url', 'twitter_url')
        }),
        ('Files', {
            'fields': ('cv_file',)
        }),
        ('Statistiche', {
            'fields': ('projects_completed', 'sites_live', 'years_experience', 'happy_clients'),
            'description': 'Numeri mostrati nella sezione statistiche'
        }),
    )
    
    def has_add_permission(self, request):
        """Prevent creating more than one instance."""
        return not SiteSettings.objects.exists()
    
    def has_delete_permission(self, request, obj=None):
        """Prevent deletion of settings."""
        return False


@admin.register(ContactMessage)
class ContactMessageAdmin(admin.ModelAdmin):
    """Admin configuration for ContactMessage model."""
    
    list_display = [
        'read_status',
        'name',
        'email',
        'subject',
        'created_at'
    ]
    list_display_links = ['name', 'email']
    list_filter = ['is_read', 'created_at']
    search_fields = ['name', 'email', 'subject', 'message']
    ordering = ['-created_at']
    readonly_fields = ['name', 'email', 'subject', 'message', 'created_at']
    
    def read_status(self, obj):
        """Display read status as icon."""
        if obj.is_read:
            return format_html(
                '<span style="color: #4ade80;">✓</span>'
            )
        return format_html(
            '<span style="color: #00d9ff; font-weight: bold;">●</span>'
        )
    read_status.short_description = ''
    
    def has_add_permission(self, request):
        """Prevent adding messages manually."""
        return False
    
    def change_view(self, request, object_id, form_url='', extra_context=None):
        """Mark message as read when viewing."""
        obj = self.get_object(request, object_id)
        if obj and not obj.is_read:
            obj.is_read = True
            obj.save()
        return super().change_view(request, object_id, form_url, extra_context)
